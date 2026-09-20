// Sección 9: IMC por rangos y bordes (18,5 / 25 / 30). RF-03.
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis/dominio/logica/imc.dart';

void main() {
  group('calcularImc', () {
    test('aplica peso / altura² en metros', () {
      final imc = calcularImc(pesoKg: 70, alturaCm: 175);
      expect(imc, closeTo(22.86, 0.01));
    });

    test('devuelve null con altura o peso no plausibles', () {
      expect(calcularImc(pesoKg: 70, alturaCm: 0), isNull);
      expect(calcularImc(pesoKg: 0, alturaCm: 170), isNull);
      expect(calcularImc(pesoKg: -5, alturaCm: 170), isNull);
    });
  });

  group('bandaDeImc — bordes de la tabla de la sección 4.1', () {
    test('por debajo de 18,5 es bajo peso', () {
      expect(bandaDeImc(18.49), BandaImc.bajoPeso);
    });

    test('18,5 exacto ya es rango saludable', () {
      expect(bandaDeImc(18.5), BandaImc.saludable);
    });

    test('24,99 sigue siendo saludable y 25 exacto es sobrepeso', () {
      expect(bandaDeImc(24.99), BandaImc.saludable);
      expect(bandaDeImc(25), BandaImc.sobrepeso);
    });

    test('29,99 es sobrepeso y 30 exacto es obesidad', () {
      expect(bandaDeImc(29.99), BandaImc.sobrepeso);
      expect(bandaDeImc(30), BandaImc.obesidad);
    });
  });

  test('formatearImc usa coma decimal', () {
    expect(formatearImc(22.857), '22,9');
  });
}
