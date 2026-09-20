/// Rutinas, pasos y sesiones de entreno. Sección 5 · sección 4.5.
library;

import 'enums.dart';

/// Un paso de la rutina: trabajo o descanso.
class Paso {
  const Paso({
    required this.tipo,
    required this.nombre,
    required this.detalle,
    required this.duracionS,
    required this.indicacion,
  });

  final TipoPaso tipo;
  final String nombre;
  final String detalle;
  final int duracionS;

  /// Indicación breve de técnica; también la lee el lector de pantalla.
  final String indicacion;

  bool get esTrabajo => tipo == TipoPaso.trabajo;
}

/// Una rutina completa con su «por qué» (RF-41).
class Rutina {
  const Rutina({
    required this.id,
    required this.nombre,
    required this.duracionMin,
    required this.material,
    required this.impacto,
    required this.porque,
    required this.notaAdaptacion,
    required this.pasos,
  });

  final String id;
  final String nombre;
  final int duracionMin;
  final String material;
  final String impacto;

  /// Por qué Vitalis recomienda esta rutina. La app recomienda, no manda.
  final String porque;

  /// Cómo se adapta la rutina a las necesidades declaradas (RF-40).
  final String notaAdaptacion;

  final List<Paso> pasos;

  int get numeroEjercicios =>
      pasos.where((p) => p.tipo == TipoPaso.trabajo).length;

  /// Resumen leído como un solo nodo por el lector de pantalla (AC-03).
  String get textoAccesible =>
      '$nombre. $duracionMin minutos, $numeroEjercicios ejercicios. '
      'Material: $material. Impacto $impacto. $porque';
}

/// Sesión registrada; alimenta el resumen semanal (RF-42).
class SesionEntreno {
  const SesionEntreno({
    required this.rutinaId,
    required this.fecha,
    required this.completada,
    required this.pasoActual,
  });

  final String rutinaId;

  /// Día de la sesión, normalizado a medianoche.
  final DateTime fecha;
  final bool completada;
  final int pasoActual;

  Map<String, Object?> aJson() => {
        'rutinaId': rutinaId,
        'fecha': _soloFecha(fecha),
        'completada': completada,
        'pasoActual': pasoActual,
      };

  static SesionEntreno desdeJson(Map<String, Object?> json) => SesionEntreno(
        rutinaId: json['rutinaId'] as String,
        fecha: DateTime.parse(json['fecha'] as String),
        completada: json['completada'] as bool,
        pasoActual: json['pasoActual'] as int,
      );

  static String _soloFecha(DateTime fecha) =>
      '${fecha.year.toString().padLeft(4, '0')}-'
      '${fecha.month.toString().padLeft(2, '0')}-'
      '${fecha.day.toString().padLeft(2, '0')}';
}
