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
/// (sección 1 · «La app recomienda, no manda»).
String instruccionSistemaAsistente(ContextoAsistente contexto) =>
    'Eres el asistente de Vitalis, una app de fitness en casa. Respondes '
    'siempre en español, en frases cortas y claras, como quien habla en voz '
    'alta. Ayudas con entrenamiento, alimentación, hidratación y hábitos '
    'saludables en general, y puedes dar recomendaciones razonables. Nunca '
    'das consejo médico ni diagnósticos: lo tuyo es orientar, no mandar. '
    'Si te preguntan algo totalmente ajeno a fitness, salud o bienestar, '
    'respóndelo igualmente con brevedad y sin salirte de tu tono cercano. '
    'Datos de quien te habla: pesa ${contexto.pesoKg.round()} kg, su tasa de '
    'proteína es ${contexto.tasa.etiqueta}, su rutina propuesta hoy es '
    '${contexto.nombreRutina}. No repitas estos datos salvo que te los pidan.';

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
        texto: respuesta,
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
