// Sección 9: clasificador de intenciones. RF-12, sección 4.6.
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis/dominio/logica/clasificador_intenciones.dart';
import 'package:vitalis/dominio/modelos/enums.dart';

void main() {
  test('reconoce el plan de comidas', () {
    for (final frase in [
      'dame mi plan',
      '¿Cuánta PROTEÍNA necesito hoy?',
      'quiero mi dieta',
      'qué comida toca hoy',
    ]) {
      expect(clasificarIntencion(frase), Intencion.plan, reason: frase);
    }
  });

  test('reconoce el agua', () {
    for (final frase in [
      'apunta 250 ml de agua',
      'acabo de beber',
      'un vaso más',
      'cómo voy de hidratación',
    ]) {
      expect(clasificarIntencion(frase), Intencion.agua, reason: frase);
    }
  });

  test('reconoce el entreno', () {
    for (final frase in [
      'qué entreno toca hoy',
      'empieza la RUTINA',
      'quiero entrenar',
      'dame ejercicios',
    ]) {
      expect(clasificarIntencion(frase), Intencion.entreno, reason: frase);
    }
  });

  test('no distingue mayúsculas ni acentos', () {
    expect(clasificarIntencion('PROTEINA'), Intencion.plan);
    expect(clasificarIntencion('proteína'), Intencion.plan);
    expect(clasificarIntencion('HIDRATACIÓN'), Intencion.agua);
  });

  test('con varias palabras gana la que aparece antes', () {
    expect(
      clasificarIntencion('quiero agua antes del entreno'),
      Intencion.agua,
    );
    expect(
      clasificarIntencion('el entreno de hoy y luego agua'),
      Intencion.entreno,
    );
  });

  test('lo que no reconoce queda como desconocida, sin inventar', () {
    expect(clasificarIntencion('cuéntame un chiste'), Intencion.desconocida);
    expect(clasificarIntencion(''), Intencion.desconocida);
    expect(clasificarIntencion('   '), Intencion.desconocida);
  });

  test('ofrece exactamente tres ejemplos al no entender (RF-12)', () {
    expect(ejemplosSugeridos, hasLength(3));
    expect(sugerenciasInicio, hasLength(3));
  });

  test('normalizar quita acentos y baja a minúsculas', () {
    expect(normalizar('Ñandú ÁÉÍÓÚ'), 'nandu aeiou');
  });
}
