/// Entidades del plan de comidas. Sección 5 · RF-22.
library;

import 'enums.dart';

/// Una comida del plan diario.
class Comida {
  const Comida({
    required this.hora,
    required this.plato,
    required this.ingredientes,
    required this.proteinaG,
    required this.kcal,
  });

  /// Hora en formato HH:MM.
  final String hora;
  final String plato;
  final List<String> ingredientes;
  final int proteinaG;
  final int kcal;

  /// Texto accesible por fila exigido por la sección 4.3:
  /// «Comida N a las HH:MM: plato, X gramos de proteína, Y kilocalorías».
  String textoAccesible(int numero) =>
      'Comida $numero a las $hora: $plato, '
      '$proteinaG gramos de proteína, $kcal kilocalorías. '
      'Ingredientes: ${ingredientes.join(', ')}.';

  Map<String, Object?> aJson() => {
        'hora': hora,
        'plato': plato,
        'ingredientes': ingredientes,
        'proteinaG': proteinaG,
        'kcal': kcal,
      };

  static Comida desdeJson(Map<String, Object?> json) => Comida(
        hora: json['hora'] as String,
        plato: json['plato'] as String,
        ingredientes: (json['ingredientes'] as List<Object?>).cast<String>(),
        proteinaG: json['proteinaG'] as int,
        kcal: json['kcal'] as int,
      );
}

/// Plan diario de cuatro comidas.
class PlanComidas {
  const PlanComidas({
    required this.fecha,
    required this.objetivoProteinaG,
    required this.tasa,
    required this.preferencia,
    required this.comidas,
    required this.porque,
  });

  final DateTime fecha;
  final int objetivoProteinaG;
  final TasaProteina tasa;
  final PreferenciaDieta preferencia;
  final List<Comida> comidas;

  /// Explicación «Por qué este plan» (RF-23).
  final String porque;

  /// Totales = suma de comidas; pueden diferir ±1 g del objetivo por redondeo.
  int get totalProteinaG =>
      comidas.fold(0, (suma, comida) => suma + comida.proteinaG);

  int get totalKcal => comidas.fold(0, (suma, comida) => suma + comida.kcal);

  Map<String, Object?> aJson() => {
        'fecha': fecha.toIso8601String(),
        'objetivoProteinaG': objetivoProteinaG,
        'tasa': tasa.name,
        'preferencia': preferencia.name,
        'porque': porque,
        'comidas': comidas.map((c) => c.aJson()).toList(),
      };

  static PlanComidas desdeJson(Map<String, Object?> json) => PlanComidas(
        fecha: DateTime.parse(json['fecha'] as String),
        objetivoProteinaG: json['objetivoProteinaG'] as int,
        tasa: TasaProteina.values.byName(json['tasa'] as String),
        preferencia:
            PreferenciaDieta.values.byName(json['preferencia'] as String),
        porque: json['porque'] as String,
        comidas: (json['comidas'] as List<Object?>)
            .map((c) => Comida.desdeJson((c as Map).cast<String, Object?>()))
            .toList(),
      );
}
