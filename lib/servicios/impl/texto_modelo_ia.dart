/// Arreglo de un límite conocido del motor de IA local (MediaPipe LLM
/// Inference), no de este código.
library;

import 'dart:convert';

/// Repara el texto cuando el motor nativo parte un carácter multibyte
/// (tilde, «¿», «¡»...) entre dos trozos de una respuesta en streaming: cada
/// mitad se decodifica por su cuenta como Latin-1 en vez de UTF-8, y el
/// resultado sale como «Â¡Hola!» en vez de «¡Hola!».
///
/// El truco: si [texto] es en realidad UTF-8 mal reinterpretado como
/// Latin-1, sus bytes en Latin-1 son los bytes UTF-8 originales, así que
/// decodificarlos de nuevo como UTF-8 reconstruye el texto correcto. Si
/// [texto] ya estaba bien (el caso normal) o tiene algún carácter fuera de
/// Latin-1 (emoji, rayas largas...), `latin1.encode`/`utf8.decode` fallan y
/// se devuelve tal cual: no hay forma de que esto estropee un texto bueno.
String repararMojibake(String texto) {
  try {
    return utf8.decode(latin1.encode(texto));
  } catch (_) {
    return texto;
  }
}
