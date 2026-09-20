// Sección 9: tope de agua. RF-30, RF-31.
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis/dominio/logica/hidratacion.dart';

void main() {
  test('suma incrementos normales', () {
    expect(registrarAgua(actualMl: 500, incrementoMl: 250), 750);
    expect(registrarAgua(actualMl: 500, incrementoMl: 500), 1000);
  });

  test('nunca supera el tope de 3.000 ml', () {
    expect(registrarAgua(actualMl: 2900, incrementoMl: 500), topeDiarioMl);
    expect(registrarAgua(actualMl: 3000, incrementoMl: 250), 3000);
  });

  test('nunca baja de cero', () {
    expect(registrarAgua(actualMl: 100, incrementoMl: -500), 0);
  });

  test('el progreso se acota a 1 aunque se pase de la meta', () {
    expect(progresoAgua(0), 0);
    expect(progresoAgua(1250), 0.5);
    expect(progresoAgua(2500), 1);
    expect(progresoAgua(3000), 1);
  });

  test('cuenta los vasos que faltan para la meta', () {
    expect(vasosRestantes(1250), 5);
    expect(vasosRestantes(2500), 0);
    expect(vasosRestantes(3000), 0);
  });

  test('la frase de estado concuerda en número', () {
    expect(fraseHidratacion(1250), contains('5 vasos'));
    expect(fraseHidratacion(2250), contains('1 vaso para'));
    expect(fraseHidratacion(2500), contains('cumplida'));
  });
}
