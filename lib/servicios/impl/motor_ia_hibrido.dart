/// Motor de IA híbrido: reglas deterministas + modelo de lenguaje real.
/// ADR-03.
///
/// Lo estructurado (plan, agua, entreno) sigue resolviéndose por fórmula: un
/// LLM no debe inventar gramos de proteína ni kilocalorías (sección 4.3,
/// RF-25). Solo la conversación libre —cuando no hay una intención clara—
/// se apoya en el modelo real, y solo si hay uno cargado.
library;

import 'dart:convert';

import '../../dominio/catalogo/platos.dart';
import '../../dominio/logica/clasificador_intenciones.dart';
import '../../dominio/logica/generador_plan.dart';
import '../../dominio/logica/proteina.dart';
import '../../dominio/modelos/enums.dart';
import '../../dominio/modelos/mensaje.dart';
import '../../dominio/modelos/plan_comidas.dart';
import '../contratos/contratos.dart';

/// Instrucción de sistema del asistente conversacional.
///
/// Fija el idioma, el tono, el ámbito (fitness/dieta/agua en casa) y los
/// límites: nada de consejo médico, orientativo como el resto de la app
/// (sección 1 · «La app recomienda, no manda»). También fija la variante de
/// español (Perú) y una regla de tono prioritaria e innegociable sobre el
/// cuerpo o el peso de la persona.
///
/// Deliberadamente corta: este texto se reprocesa entero cada vez que arranca
/// una conversación (RF-16), así que menos tokens de prefill es menos espera
/// antes de la primera respuesta del chat de voz.
String instruccionSistemaAsistente(ContextoAsistente contexto) =>
    'Eres el asistente de Vitalis, app peruana de fitness en casa. '
    'Responde siempre en español de Perú, en frases muy cortas, como si '
    'hablaras en voz alta. Usa palabras y platos peruanos (papa, camote, '
    'choclo, palta, ají, menestras), nunca de España. Ayudas con entreno, '
    'comida, agua y hábitos sanos; no das consejo médico. '
    'Regla innegociable: nunca comentes el cuerpo o el peso de la persona '
    'en tono negativo ni burlón; sé siempre respetuoso. '
    'Usa lo último que te dijo la persona; no repitas respuestas. '
    'Si preguntan algo fuera de fitness, responde breve y con el mismo tono. '
    'Datos: pesa ${contexto.pesoKg.round()} kg, tasa '
    '${contexto.tasa.etiqueta}, rutina de hoy: ${contexto.nombreRutina}.';

/// Términos claramente despectivos sobre cuerpo o peso.
///
/// Red de seguridad determinista además del prompt (sección «Regla de
/// tono»): un modelo de 0,5 B corriendo en el dispositivo no da garantías de
/// que el prompt se respete siempre, así que la salida se revisa antes de
/// mostrarla u oírla.
const List<String> _terminosDespectivosCuerpo = [
  'gorda',
  'gordo',
  'gordita',
  'gordito',
  'obesa',
  'obeso',
  'foca',
  'ballena',
  'fofa',
  'fofo',
  'fea',
  'feo',
  'fracasada',
  'fracasado',
];

/// Respuesta fija cuando la salida del modelo se descarta por tono.
const String _respuestaTonoDescartado =
    'Prefiero no entrar en eso. Cuéntame qué has comido, cómo va tu '
    'hidratación o cómo te sientes con el entrenamiento y seguimos.';

/// True si [texto] contiene algún término despectivo sobre cuerpo o peso.
bool _tieneTonoInapropiado(String texto) {
  final normalizado = normalizar(texto);
  return _terminosDespectivosCuerpo.any(normalizado.contains);
}

/// Instrucción de sistema para generar recetas, separada de la del asistente
/// conversacional: es un rol distinto (redactor de recetas, no un chat) con
/// su propio chat efímero (sección 5, [GeneradorContenidoIA]).
String _instruccionGeneradorRecetas() =>
    'Eres un generador de recetas para una app peruana de fitness en casa. '
    'Devuelves solo JSON válido, sin explicaciones ni texto alrededor ni '
    'bloques de código. Usa vocabulario y platos peruanos (papa, camote, '
    'choclo, palta, ají, menestras, quinua...), nunca términos de España '
    '(nada de "judías", "patata", "boniato" ni "aguacate"). No incluyas '
    'cantidades ni gramos: de eso ya se encarga la app.';

String _peticionRecetas(PreferenciaDieta preferencia) =>
    'Propón 4 platos peruanos, uno para cada una de estas franjas en este '
    'orden: ${nombresFranjas.join(', ')}. La dieta es '
    '"${preferencia.etiqueta}". Responde solo con este JSON, una lista de '
    'exactamente 4 objetos: '
    '[{"nombre": "...", "ingredientes": ["...", "..."]}, ...]';

/// Recorta cualquier texto que el modelo añada antes o después del JSON
/// (preámbulo, bloque de código...), quedándose con lo que hay entre el
/// primer `[` y el último `]`.
String _extraerJson(String texto) {
  final inicio = texto.indexOf('[');
  final fin = texto.lastIndexOf(']');
  if (inicio == -1 || fin == -1 || fin < inicio) return texto;
  return texto.substring(inicio, fin + 1);
}

/// Valida y convierte la respuesta cruda del generador en 4 platos. Cualquier
/// cosa que no encaje (JSON inválido, longitud distinta de 4, campos vacíos o
/// del tipo equivocado) devuelve `null`: quien llama cae al catálogo.
List<PlatoBase>? _parsearPlatosGenerados(String? crudo) {
  if (crudo == null) return null;
  try {
    final decodificado = jsonDecode(_extraerJson(crudo));
    if (decodificado is! List || decodificado.length != 4) return null;
    final platos = <PlatoBase>[];
    for (final item in decodificado) {
      if (item is! Map) return null;
      final nombre = item['nombre'];
      final ingredientes = item['ingredientes'];
      if (nombre is! String || nombre.trim().isEmpty) return null;
      if (ingredientes is! List || ingredientes.isEmpty) return null;
      platos.add(
        PlatoBase(nombre.trim(), ingredientes.map((e) => '$e').toList()),
      );
    }
    return platos;
  } on FormatException {
    return null;
  }
}

/// «Por qué este plan» cuando los platos los ha propuesto la IA, en vez del
/// catálogo (sección 4.3, RF-23).
String _explicarPlanIA({
  required double pesoKg,
  required TasaProteina tasa,
  required PreferenciaDieta preferencia,
  required int objetivoG,
}) {
  final peso = pesoKg.toStringAsFixed(1).replaceAll('.', ',');
  final gkg = tasa.gPorKg.toStringAsFixed(1).replaceAll('.', ',');
  return 'Parto de tus $peso kg y de la tasa «${tasa.etiqueta}» '
      '($gkg g/kg), así que el día suma $objetivoG g de proteína. '
      'Reparto el 30 % en el desayuno, el 35 % en la comida, el 20 % en la '
      'merienda y el 15 % en la cena, para que ninguna toma se quede corta. '
      'Los platos los ha propuesto la IA local para la preferencia '
      '«${preferencia.etiqueta}»: la preferencia cambia qué comes, nunca '
      'cuánta proteína necesitas. Es una orientación, no una pauta médica.';
}

class MotorIAHibrido implements MotorIA {
  MotorIAHibrido({
    required this.base,
    required this.gestor,
    required this.conversador,
    required this.generador,
    required this.reloj,
    required this.obtenerContexto,
  });

  /// Motor por reglas: sigue resolviendo lo estructurado.
  final MotorIA base;

  final GestorModeloIA gestor;
  final ConversadorIA conversador;

  /// Genera los platos del plan cuando hay modelo disponible; nunca decide
  /// gramos de proteína ni kilocalorías (ADR-03, RF-25), solo el nombre y los
  /// ingredientes de cada plato.
  final GeneradorContenidoIA generador;

  final Reloj reloj;
  final ContextoAsistente Function() obtenerContexto;

  bool _conversacionIniciada = false;

  @override
  List<String> get pasosDeGeneracion => base.pasosDeGeneracion;

  @override
  bool get conversacionDisponible => gestor.estado == EstadoModeloIA.listo;

  @override
  Future<PlanComidas> generarPlan({
    required double pesoKg,
    required TasaProteina tasa,
    required PreferenciaDieta preferencia,
    int semilla = 0,
  }) async {
    final platosIA = conversacionDisponible
        ? _parsearPlatosGenerados(
            await generador.generar(
              instruccionSistema: _instruccionGeneradorRecetas(),
              peticion: _peticionRecetas(preferencia),
            ),
          )
        : null;

    if (platosIA == null) {
      return base.generarPlan(
        pesoKg: pesoKg,
        tasa: tasa,
        preferencia: preferencia,
        semilla: semilla,
      );
    }

    final objetivo = proteinaObjetivoG(pesoKg: pesoKg, tasa: tasa);
    final comidas = <Comida>[
      for (var i = 0; i < repartoProteina.length; i++)
        Comida(
          hora: horasComidas[i],
          plato: platosIA[i].nombre,
          ingredientes: platosIA[i].ingredientes,
          proteinaG: (objetivo * repartoProteina[i]).round(),
          kcal: kcalDesdeProteina((objetivo * repartoProteina[i]).round()),
        ),
    ];

    final hoy = reloj.ahora();
    return PlanComidas(
      fecha: DateTime(hoy.year, hoy.month, hoy.day),
      objetivoProteinaG: objetivo,
      tasa: tasa,
      preferencia: preferencia,
      comidas: comidas,
      porque: _explicarPlanIA(
        pesoKg: pesoKg,
        tasa: tasa,
        preferencia: preferencia,
        objetivoG: objetivo,
      ),
    );
  }

  @override
  Future<RespuestaAsistente> responder(
    String texto, {
    List<Mensaje> historial = const [],
  }) async {
    final intencion = clasificarIntencion(texto);
    // Lo reconocido (plan/agua/entreno) siempre por reglas, con datos exactos.
    if (intencion != Intencion.desconocida || !conversacionDisponible) {
      return base.responder(texto, historial: historial);
    }

    try {
      if (!_conversacionIniciada) {
        await conversador.reiniciar(
          instruccionSistema: instruccionSistemaAsistente(obtenerContexto()),
        );
        _conversacionIniciada = true;
      }
      final respuesta = await conversador.responder(texto);
      return RespuestaAsistente(
        intencion: Intencion.desconocida,
        texto: _tieneTonoInapropiado(respuesta)
            ? _respuestaTonoDescartado
            : respuesta,
        esConversacionLibre: true,
      );
    } catch (_) {
      // Cualquier fallo del motor real —Exception, Error del plugin nativo,
      // lo que sea— nunca deja a la persona sin respuesta: se cae a la
      // plantilla fija del motor por reglas. Es un límite deliberado con un
      // motor externo, no un catch genérico sobre lógica propia.
      return base.responder(texto, historial: historial);
    }
  }

  /// La conversación de Inicio arranca vacía cada día (RF-16); esto hace que
  /// el próximo mensaje reinicie también la memoria del modelo, con el
  /// contexto de perfil actualizado.
  void reiniciarConversacion() {
    _conversacionIniciada = false;
  }
}
