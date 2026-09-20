/// Contratos de los servicios de dispositivo y del motor de IA. Sección 8.
///
/// El dominio no depende de la interfaz ni de los servicios; los servicios se
/// inyectan detrás de estas interfaces para poder simularlos en pruebas.
library;

import '../../dominio/modelos/enums.dart';
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
  });

  final Intencion intencion;
  final String texto;
  final PlanComidas? plan;
  final List<String> ejemplos;
}

/// Motor de IA local. Corre en el dispositivo y nunca usa la red (RNF-01).
abstract interface class MotorIA {
  /// Genera el plan del día. Solo recibe peso, tasa y preferencia (RF-25).
  Future<PlanComidas> generarPlan({
    required double pesoKg,
    required TasaProteina tasa,
    required PreferenciaDieta preferencia,
    int semilla,
  });

  /// Responde a lo que ha dicho o escrito la persona (RF-12, RF-13).
  Future<RespuestaAsistente> responder(String texto);

  /// Pasos que se muestran mientras genera (RF-15, sección 3 · Dieta).
  List<String> get pasosDeGeneracion;
}
