/// Contratos de los servicios de dispositivo y del motor de IA. Sección 8.
///
/// El dominio no depende de la interfaz ni de los servicios; los servicios se
/// inyectan detrás de estas interfaces para poder simularlos en pruebas.
library;

import '../../dominio/modelos/enums.dart';
import '../../dominio/modelos/mensaje.dart';
import '../../dominio/modelos/perfil.dart';
import '../../dominio/modelos/plan_comidas.dart';
import '../../dominio/modelos/rutina.dart';

/// Instante actual, inyectable para poder simular el reloj en pruebas.
abstract interface class Reloj {
  DateTime ahora();
}

/// Lectura, escritura, borrado y exportación de todo lo que persiste.
///
/// Nada de esto sale del dispositivo (RNF-01, RNF-10).
abstract interface class Almacen {
  Future<Perfil?> leerPerfil();
  Future<void> guardarPerfil(Perfil perfil);

  Future<Preferencias?> leerPreferencias();
  Future<void> guardarPreferencias(Preferencias preferencias);

  /// Plan activo del día. Devuelve `null` si no hay o si es de otro día.
  Future<PlanComidas?> leerPlan();
  Future<void> guardarPlan(PlanComidas plan);

  /// Mililitros registrados en [dia]. El agua se reinicia cada día.
  Future<int> leerAgua(DateTime dia);
  Future<void> guardarAgua(DateTime dia, int ml);

  Future<List<SesionEntreno>> leerSesiones();
  Future<void> guardarSesion(SesionEntreno sesion);

  /// URL desde la que se descargó el modelo de IA local real, si hay uno
  /// instalado. Sirve para restaurarlo al arrancar sin volver a descargarlo.
  Future<String?> leerUrlModeloIA();
  Future<void> guardarUrlModeloIA(String? url);

  /// Rutina generada por IA para [dia]. Devuelve `null` si no hay ninguna
  /// guardada para ese día (mismo criterio por día que [leerAgua]).
  Future<Rutina?> leerRutinaIA(DateTime dia);
  Future<void> guardarRutinaIA(DateTime dia, Rutina rutina);

  /// Volcado legible de todo lo guardado (RF-52).
  Future<String> exportar();

  /// «Borrar mis datos» (pendiente recogido en la sección 5).
  Future<void> borrarTodo();
}

/// Resultado parcial o final del dictado.
class Transcripcion {
  const Transcripcion({required this.texto, required this.definitiva});

  final String texto;
  final bool definitiva;
}

/// Dictado por voz. Toda función de voz tiene alternativa de texto (AC-11).
abstract interface class Voz {
  /// ¿Hay dictado disponible en este dispositivo?
  Future<bool> disponible();

  /// Arranca el dictado y emite transcripción en vivo (RF-11).
  Future<void> escuchar({
    required void Function(Transcripcion) alTranscribir,
    required void Function(Object error) alFallar,
  });

  Future<void> detener();

  bool get escuchando;
}

/// Patrones hápticos. Cada vibración tiene gemela visual (AC-12).
abstract interface class Haptico {
  /// Comienzo de una fase del reproductor.
  Future<void> inicioFase();

  /// Tres segundos antes del final (RF-61).
  Future<void> tresSegundos();

  /// Final de la fase.
  Future<void> finFase();

  /// Confirmación de una acción (abrir o cerrar el dictado, AC-08).
  Future<void> confirmacion();
}

/// Prioridad del anuncio al lector de pantalla.
enum PrioridadAnuncio { cortes, educado }

/// Anuncios al lector de pantalla para las regiones vivas (AC-07).
abstract interface class Anunciador {
  void anunciar(String mensaje, {PrioridadAnuncio prioridad});
}

/// Lo que el motor necesita saber del estado para responder.
///
/// Se inyecta con una función para que `responder(texto)` mantenga la firma
/// del contrato de la sección 8 y siga siendo simulable en pruebas.
class ContextoAsistente {
  const ContextoAsistente({
    required this.pesoKg,
    required this.tasa,
    required this.preferencia,
    required this.aguaMl,
    required this.nombreRutina,
  });

  final double pesoKg;
  final TasaProteina tasa;
  final PreferenciaDieta preferencia;
  final int aguaMl;
  final String nombreRutina;
}

/// Respuesta del asistente: texto más la carga que pinta la tarjeta (RF-13).
class RespuestaAsistente {
  const RespuestaAsistente({
    required this.intencion,
    required this.texto,
    this.plan,
    this.ejemplos = const [],
    this.esConversacionLibre = false,
  });

  final Intencion intencion;
  final String texto;
  final PlanComidas? plan;
  final List<String> ejemplos;

  /// True cuando el texto lo generó el modelo de lenguaje real, no una
  /// plantilla fija. Distingue una respuesta conversacional (puede variar
  /// entre llamadas) de una determinista, para que la interfaz no la trate
  /// igual que a un «no entendido» con ejemplos fijos.
  final bool esConversacionLibre;
}

/// Motor de IA local. Corre en el dispositivo y nunca usa la red (RNF-01).
abstract interface class MotorIA {
  /// Genera el plan del día. Solo recibe peso, tasa y preferencia (RF-25).
  ///
  /// Siempre por fórmula, nunca por el modelo conversacional: la proteína y
  /// las kcal son datos, no algo que un LLM deba inventar (sección 4.3).
  Future<PlanComidas> generarPlan({
    required double pesoKg,
    required TasaProteina tasa,
    required PreferenciaDieta preferencia,
    int semilla,
  });

  /// Responde a lo que ha dicho o escrito la persona (RF-12, RF-13).
  ///
  /// Las intenciones reconocidas (plan/agua/entreno) siguen resolviéndose por
  /// reglas, con datos exactos. Solo la conversación libre —cuando no hay una
  /// intención clara— puede apoyarse en el modelo de lenguaje real, si hay
  /// uno cargado ([conversacionDisponible]).
  Future<RespuestaAsistente> responder(String texto, {List<Mensaje> historial});

  /// Pasos que se muestran mientras genera (RF-15, sección 3 · Dieta).
  List<String> get pasosDeGeneracion;

  /// Si hay un modelo de lenguaje real cargado y listo para conversar
  /// libremente. Sin él, lo no reconocido pide precisión con tres ejemplos
  /// (comportamiento original de la sección 4.6) en vez de generar texto.
  bool get conversacionDisponible;
}

/// Estado del modelo de IA local real (un LLM cuantizado). Sección 8 · ADR-03.
enum EstadoModeloIA {
  /// Todavía no se ha descargado ningún modelo.
  sinInstalar,

  /// Descarga en curso; ver [GestorModeloIA.progreso].
  descargando,

  /// Modelo descargado y cargado: el asistente puede conversar libremente.
  listo,

  /// La última descarga o carga falló; ver [GestorModeloIA.error].
  error,
}

/// Ciclo de vida del modelo de IA local: descargarlo, seguir el progreso,
/// cancelarlo o borrarlo. Independiente de [MotorIA]: el motor solo pregunta
/// si hay un modelo listo, no cómo llegó a estarlo.
///
/// El modelo no puede ir empaquetado en la app (pesa cientos de MB a varios
/// GB): se descarga la primera vez que la persona lo pide, nunca sola.
abstract interface class GestorModeloIA {
  EstadoModeloIA get estado;

  /// Emite cada vez que cambia [estado] (incluidas las actualizaciones de
  /// [progreso] mientras descarga).
  Stream<EstadoModeloIA> get cambiosDeEstado;

  /// Progreso de la descarga en curso, de 0 a 1.
  double get progreso;

  /// Motivo del último fallo, si [estado] es [EstadoModeloIA.error].
  String? get error;

  /// Descarga el modelo desde [urlModelo]. Algunos modelos (p. ej. Gemma)
  /// exigen aceptar su licencia en Hugging Face y pasar el token de acceso
  /// de esa cuenta en [tokenHuggingFace]; sin él, la descarga falla con 401.
  Future<void> descargar({required String urlModelo, String? tokenHuggingFace});

  Future<void> cancelarDescarga();

  /// Borra el modelo descargado. Después, [conversacionDisponible] vuelve a
  /// ser falso hasta la siguiente descarga.
  Future<void> eliminarModelo();
}

/// Síntesis de voz: el asistente lee sus respuestas en voz alta.
///
/// Usa el motor de voz del sistema, offline en ambas plataformas (RNF-01).
abstract interface class SintesisVoz {
  Future<void> hablar(String texto);

  Future<void> detener();

  bool get hablando;
}

/// Llamada cruda al modelo de lenguaje real, con su propia memoria de turnos.
///
/// Separado de [MotorIA] para poder simularlo en pruebas: [MotorIA] decide
/// *cuándo* conversar libremente (sección 4.6), esto decide *cómo* hablar con
/// el modelo. La implementación real vive detrás de flutter_gemma.
abstract interface class ConversadorIA {
  /// Empieza una conversación nueva con esta instrucción de sistema.
  Future<void> reiniciar({required String instruccionSistema});

  /// Responde dentro de la conversación en curso.
  Future<String> responder(String texto);
}

/// Generación de contenido de una sola vuelta (recetas, ejercicios...), sin
/// memoria de turnos. Separado de [ConversadorIA] porque no comparte su
/// sesión: no debe mezclarse con la memoria de la conversación del
/// asistente ni verse afectado por ella. Devuelve `null` si el modelo no
/// está disponible o la generación falla; quien lo llama decide el
/// catálogo de respaldo.
abstract interface class GeneradorContenidoIA {
  Future<String?> generar({
    required String instruccionSistema,
    required String peticion,
  });
}
