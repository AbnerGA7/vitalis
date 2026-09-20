// Sección 9: conversión de unidades. RF-02.
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis/dominio/logica/unidades.dart';

void main() {
  test('libras y kilos son inversos', () {
    expect(librasAKg(154.324), closeTo(70, 0.01));
    expect(kgALibras(70), closeTo(154.32, 0.01));
  });

  test('pulgadas y centímetros son inversos', () {
    expect(pulgadasACm(70), closeTo(177.8, 0.01));
    expect(cmAPulgadas(177.8), closeTo(70, 0.01));
  });

  test('175 cm son 5 pies y 9 pulgadas', () {
    final altura = cmAPiesPulgadas(175);
    expect(altura.pies, 5);
    expect(altura.pulgadas, 9);
  });

  test('pies y pulgadas vuelven a centímetros', () {
    expect(piesPulgadasACm(5, 9), closeTo(175.26, 0.01));
  });

  test('formatearNumero usa coma y quita decimales sobrantes', () {
    expect(formatearNumero(70.0), '70');
    expect(formatearNumero(70.5), '70,5');
  });
}
