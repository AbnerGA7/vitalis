/// Generación de contenido de una sola vuelta contra el modelo de lenguaje
/// local. ADR-03.
///
/// A diferencia de [ConversadorGemma], no mantiene sesión propia: cada
/// llamada abre su propio chat efímero, para no mezclar memoria con la
/// conversación del asistente ni arrastrar contexto entre generaciones
/// sucesivas (p. ej. un plan de comidas nuevo no debe heredar los platos del
/// plan anterior). Nunca abre red: todo el cálculo ocurre en el dispositivo
/// (RNF-01).
library;

import 'package:flutter_gemma/flutter_gemma.dart';

import '../contratos/contratos.dart';

class GeneradorContenidoGemma implements GeneradorContenidoIA {
  @override
  Future<String?> generar({
    required String instruccionSistema,
    required String peticion,
  }) async {
    try {
      final modelo = await FlutterGemma.getActiveModel(maxTokens: 1024);
      final chat = await modelo.createChat(
        systemInstruction: instruccionSistema,
        maxOutputTokens: 500,
        temperature: 0.8,
      );
      await chat.addQuery(Message.text(text: peticion, isUser: true));
      final respuesta = await chat.generateChatResponse();
      return switch (respuesta) {
        TextResponse(:final token) =>
          token.trim().isEmpty ? null : token.trim(),
        _ => null,
      };
    } catch (_) {
      // Sin modelo listo, error del plugin nativo, lo que sea: se traduce en
      // null y quien llama cae al catálogo de respaldo (sección 4.3, 4.5).
      return null;
    }
  }
}
