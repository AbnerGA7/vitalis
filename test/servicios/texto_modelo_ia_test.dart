// Repara el mojibake que a veces produce el streaming del motor nativo
// (MediaPipe LLM Inference) al partir un carácter multibyte entre trozos.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis/servicios/impl/texto_modelo_ia.dart';

/// Simula la corrupción real: toma un texto correcto, lo codifica en UTF-8 y
/// reinterpreta esos mismos bytes como Latin-1, tal y como hace el motor
/// nativo cuando decodifica cada trozo del streaming por su cuenta.
String _mojibakear(String correcto) => latin1.decode(utf8.encode(correcto));

void main() {
  test('repara texto con tildes, «¡» y «¿» corrompido a mojibake', () {
    const original = '¡Hola! ¿Cómo estás? Aquí, allá, mañana.';
    expect(repararMojibake(_mojibakear(original)), original);
  });

  test('no toca un texto que ya estaba bien', () {
    const texto = '¡Hola! ¿Cómo estás?';
    expect(repararMojibake(texto), texto);
  });

  test('no toca texto ASCII puro', () {
    const texto = 'Hello, how are you?';
    expect(repararMojibake(texto), texto);
  });

  test('no rompe texto con caracteres fuera de Latin-1 (emoji, rayas)', () {
    const texto = 'Prueba — con raya larga y emoji 😀';
    expect(repararMojibake(texto), texto);
  });

  test('el caso real visto en la app: «Â¡Hola!» pasa a «¡Hola!»', () {
    expect(repararMojibake('Â¡Hola!'), '¡Hola!');
  });
}
