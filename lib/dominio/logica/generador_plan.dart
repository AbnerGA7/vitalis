/// Generación del plan de cuatro comidas. Sección 4.3 · RF-22, RF-24, RF-25.
///
/// Lógica pura: no hace E/S ni conoce la interfaz. La única entrada son peso,
/// tasa y preferencia (RF-25).
library;

import 'dart:math';

import '../catalogo/platos.dart';
import '../modelos/enums.dart';
import '../modelos/plan_comidas.dart';
import 'proteina.dart';

/// Reparto de proteína entre las cuatro comidas. Sección 4.3.
const List<double> repartoProteina = [0.30, 0.35, 0.20, 0.15];

/// Energía estimada: el 32 % de las kcal viene de la proteína.
///
/// kcal = round(prot_g × 4 / 0,32 / 10) × 10
int kcalDesdeProteina(int proteinaG) =>
    (proteinaG * 4 / 0.32 / 10).round() * 10;

/// Genera el plan del día.
///
/// [semilla] permite que «Regenerar» (RF-24) devuelva platos distintos de forma
/// reproducible y que las pruebas sean deterministas.
PlanComidas generarPlanDelDia({
  required double pesoKg,
  required TasaProteina tasa,
  required PreferenciaDieta preferencia,
  required DateTime fecha,
  int semilla = 0,
}) {
  final objetivo = proteinaObjetivoG(pesoKg: pesoKg, tasa: tasa);
  final catalogo = catalogoPlatos[preferencia]!;
  final azar = Random(semilla);

  final comidas = <Comida>[];
  for (var i = 0; i < repartoProteina.length; i++) {
    final proteinaG = (objetivo * repartoProteina[i]).round();
    final opciones = catalogo[i];
    final plato = opciones[azar.nextInt(opciones.length)];
    comidas.add(
      Comida(
        hora: horasComidas[i],
        plato: plato.nombre,
        ingredientes: plato.ingredientes,
        proteinaG: proteinaG,
        kcal: kcalDesdeProteina(proteinaG),
      ),
    );
  }

  return PlanComidas(
    fecha: DateTime(fecha.year, fecha.month, fecha.day),
    objetivoProteinaG: objetivo,
    tasa: tasa,
    preferencia: preferencia,
    comidas: comidas,
    porque: explicarPlan(
      pesoKg: pesoKg,
      tasa: tasa,
      preferencia: preferencia,
      objetivoG: objetivo,
    ),
  );
}

/// Texto «Por qué este plan» (RF-23). La app recomienda, no manda: cada plan
/// explica su razón.
String explicarPlan({
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
      'Los platos salen del catálogo «${preferencia.etiqueta}»: la preferencia '
      'cambia qué comes, nunca cuánta proteína necesitas. '
      'Es una orientación, no una pauta médica.';
}
