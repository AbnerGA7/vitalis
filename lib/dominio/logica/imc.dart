/// Cálculo del índice de masa corporal. Sección 4.1 · RF-03.
///
/// Es orientativo, nunca diagnóstico (fuera de alcance v1).
library;

/// Banda de IMC según los rangos de la sección 4.1.
enum BandaImc {
  bajoPeso('Bajo peso'),
  saludable('Rango saludable'),
  sobrepeso('Sobrepeso'),
  obesidad('Obesidad');

  const BandaImc(this.etiqueta);

  final String etiqueta;
}

/// IMC = peso_kg / (altura_m)².
///
/// Devuelve `null` si la altura no es plausible, para que la interfaz muestre
/// un estado vacío en vez de infinito o NaN.
double? calcularImc({required double pesoKg, required double alturaCm}) {
  if (alturaCm <= 0 || pesoKg <= 0) return null;
  final alturaM = alturaCm / 100;
  return pesoKg / (alturaM * alturaM);
}

/// Banda a la que pertenece un IMC. Los bordes 18,5 / 25 / 30 son inclusivos
/// por abajo, tal y como los define la tabla de la sección 4.1.
BandaImc bandaDeImc(double imc) {
  if (imc < 18.5) return BandaImc.bajoPeso;
  if (imc < 25) return BandaImc.saludable;
  if (imc < 30) return BandaImc.sobrepeso;
  return BandaImc.obesidad;
}

/// Texto del IMC con un decimal y coma decimal (interfaz en español).
String formatearImc(double imc) => imc.toStringAsFixed(1).replaceAll('.', ',');
