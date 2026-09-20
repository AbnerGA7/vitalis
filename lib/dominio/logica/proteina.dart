/// Proteína objetivo del día. Sección 4.2 · RF-20, RF-51.
library;

import '../modelos/enums.dart';

/// objetivo_g = round(peso_kg × tasa).
int proteinaObjetivoG({required double pesoKg, required TasaProteina tasa}) {
  if (pesoKg <= 0) return 0;
  return (pesoKg * tasa.gPorKg).round();
}

/// Texto de la fórmula tal y como se muestra en Dieta y en Perfil (RF-51).
String formulaProteina({required double pesoKg, required TasaProteina tasa}) {
  final peso = pesoKg.toStringAsFixed(1).replaceAll('.', ',');
  final gkg = tasa.gPorKg.toStringAsFixed(1).replaceAll('.', ',');
  final objetivo = proteinaObjetivoG(pesoKg: pesoKg, tasa: tasa);
  return '$peso kg × $gkg g/kg = $objetivo g';
}
