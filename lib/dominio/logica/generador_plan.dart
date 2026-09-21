/// Generación del plan de cuatro comidas. Sección 4.3 · RF-22, RF-24, RF-25.
///
/// Lógica pura: no hace E/S ni conoce la interfaz. La única entrada son peso,
/// tasa y preferencia (RF-25).
library;

import 'dart:math';

import '../catalogo/platos.dart';
import '../modelos/enums.dart';
import '../modelos/plan_comidas.dart';
import 'clasificador_intenciones.dart' show normalizar;
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
  String comidasFavoritas = '',
  String ingredientesEvitar = '',
}) {
  final objetivo = proteinaObjetivoG(pesoKg: pesoKg, tasa: tasa);
  final catalogo = catalogoPlatos[preferencia]!;
  final azar = Random(semilla);
  final favoritas = _palabrasDePreferencia(comidasFavoritas);
  final evitar = _palabrasDePreferencia(ingredientesEvitar);

  final comidas = <Comida>[];
  for (var i = 0; i < repartoProteina.length; i++) {
    final proteinaG = (objetivo * repartoProteina[i]).round();
    final plato = _elegirPlato(catalogo[i], favoritas, evitar, azar);
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

/// Separa un texto libre («pollo, palta y quinua») en palabras sueltas,
/// normalizadas para comparar sin acentos ni mayúsculas.
List<String> _palabrasDePreferencia(String texto) => normalizar(texto)
    .split(RegExp(r'[,;\n]+|\by\b'))
    .map((p) => p.trim())
    .where((p) => p.isNotEmpty)
    .toList();

/// Si el nombre o los ingredientes de [plato] contienen alguna de [palabras].
bool _platoMenciona(PlatoBase plato, List<String> palabras) {
  if (palabras.isEmpty) return false;
  final texto = normalizar('${plato.nombre} ${plato.ingredientes.join(' ')}');
  return palabras.any(texto.contains);
}

/// Elige un plato entre [opciones] para una franja del catálogo.
///
/// Primero descarta los que mencionan algo de [evitar] — salvo que eso deje
/// la franja sin ninguna opción, en cuyo caso se ignora el filtro: nunca se
/// deja una comida vacía por una preferencia (sección 4.3). Entre lo que
/// queda, si algo coincide con [favoritas] esa gana; si no hay preferencias
/// o ninguna coincide, decide el azar como siempre (RF-24).
PlatoBase _elegirPlato(
  List<PlatoBase> opciones,
  List<String> favoritas,
  List<String> evitar,
  Random azar,
) {
  final sinEvitadas = evitar.isEmpty
      ? opciones
      : opciones.where((p) => !_platoMenciona(p, evitar)).toList();
  final candidatas = sinEvitadas.isEmpty ? opciones : sinEvitadas;

  final favoritasEntreCandidatas =
      candidatas.where((p) => _platoMenciona(p, favoritas)).toList();
  final elegibles =
      favoritasEntreCandidatas.isEmpty ? candidatas : favoritasEntreCandidatas;

  return elegibles[azar.nextInt(elegibles.length)];
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
