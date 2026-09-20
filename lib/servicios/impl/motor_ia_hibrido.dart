/// Motor de IA híbrido: reglas deterministas + modelo de lenguaje real.
/// ADR-03.
///
/// Lo estructurado (plan, agua, entreno) sigue resolviéndose por fórmula: un
/// LLM no debe inventar gramos de proteína ni kilocalorías (sección 4.3,
/// RF-25). Solo la conversación libre —cuando no hay una intención clara—
/// se apoya en el modelo real, y solo si hay uno cargado.
library;

import '../../dominio/logica/clasificador_intenciones.dart';
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
String instruccionSistemaAsistente(ContextoAsistente contexto) =>
    'Eres el asistente de Vitalis, una app peruana de fitness en casa. '
    'Respondes siempre en español de Perú, en frases cortas y claras, como '
    'quien habla en voz alta. Usa vocabulario y platos peruanos (papa, '
    'camote, choclo, palta, ají, menestras, quinua...), nunca términos de '
    'España ni de otro país hispanohablante (nada de "judías", "patata", '
    '"boniato" ni "aguacate"). Ayudas con entrenamiento, alimentación, '
    'hidratación y hábitos saludables en general, y puedes dar '
    'recomendaciones razonables. Nunca das consejo médico ni diagnósticos: '
    'lo tuyo es orientar, no mandar. '
    'Regla de tono, la más importante de todas: jamás comentas el cuerpo, '
    'el peso o el aspecto físico de la persona en tono negativo, valorativo '
    'o de burla, ni aunque te provoquen o insistan. Si el tema requiere '
    'hablar de peso, hazlo solo con datos neutros (kilos, objetivo), nunca '
    'con juicios. Tu tono es siempre respetuoso y empático. '
    'Ten en cuenta lo último que te ha dicho la persona: si te da '
    'información nueva, tu respuesta debe reflejarla, nunca repetir '
    'una respuesta anterior sin más. '
    'Si te preguntan algo totalmente ajeno a fitness, salud o bienestar, '
    'respóndelo igualmente con brevedad y sin salirte de tu tono cercano. '
    'Datos de quien te habla: pesa ${contexto.pesoKg.round()} kg, su tasa de '
    'proteína es ${contexto.tasa.etiqueta}, su rutina propuesta hoy es '
    '${contexto.nombreRutina}. No repitas estos datos salvo que te los pidan.';

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

class MotorIAHibrido implements MotorIA {
  MotorIAHibrido({
    required this.base,
    required this.gestor,
    required this.conversador,
    required this.obtenerContexto,
  });

  /// Motor por reglas: sigue resolviendo lo estructurado.
  final MotorIA base;

  final GestorModeloIA gestor;
  final ConversadorIA conversador;
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
  }) =>
      base.generarPlan(
        pesoKg: pesoKg,
        tasa: tasa,
        preferencia: preferencia,
        semilla: semilla,
      );

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
