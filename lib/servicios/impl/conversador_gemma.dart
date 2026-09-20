/// Conversación real contra el modelo de lenguaje local. ADR-03.
///
/// Envuelve flutter_gemma (motor MediaPipe, ficheros `.task`). No abre
/// ninguna conexión: todo el cálculo ocurre en el dispositivo (RNF-01).
library;

import 'package:flutter_gemma/flutter_gemma.dart';

import '../contratos/contratos.dart';

class ConversadorGemma implements ConversadorIA {
  InferenceModel? _modelo;
  InferenceChat? _chat;

  @override
  Future<void> reiniciar({required String instruccionSistema}) async {
    await _modelo?.close();
    _modelo = await FlutterGemma.getActiveModel(maxTokens: 1024);
    _chat = await _modelo!.createChat(
      systemInstruction: instruccionSistema,
      // Respuestas más cortas generan antes: el prompt ya pide frases
      // cortas, así que 140 tokens de margen no recorta el contenido, solo
      // la latencia del chat de voz.
      maxOutputTokens: 140,
      temperature: 0.7,
    );
  }

  @override
  Future<String> responder(String texto) async {
    final chat = _chat;
    if (chat == null) {
      throw StateError('Llama a reiniciar() antes de responder().');
    }
    await chat.addQuery(Message.text(text: texto, isUser: true));
    final respuesta = await chat.generateChatResponse();
    return switch (respuesta) {
      TextResponse(:final token) => token.trim().isEmpty
          ? 'No se me ocurre nada que añadir a eso.'
          : token.trim(),
      _ => 'No he sabido responder a eso. ¿Lo intentamos de otra forma?',
    };
  }
}
