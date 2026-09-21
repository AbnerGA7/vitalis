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

import 'dart:async';

import 'package:flutter_gemma/flutter_gemma.dart';

import '../contratos/contratos.dart';

/// Tope de espera para una generación (receta o rutina). Aquí sí hace falta
/// la respuesta entera para poder parsear el JSON —a diferencia del chat, no
/// tiene sentido quedarse con un JSON a medias—, así que el tope es sobre la
/// respuesta completa, no por silencio entre tokens.
///
/// La rutina (varios ejercicios, cada uno con nombre, detalle e indicación)
/// pide bastante más texto que una receta, así que 40 s se quedaba corto y
/// la generación fallaba por tiempo antes de completar el JSON.
const Duration _tiempoMaximoGeneracion = Duration(seconds: 60);

class GeneradorContenidoGemma implements GeneradorContenidoIA {
  @override
  Future<String?> generar({
    required String instruccionSistema,
    required String peticion,
  }) async {
    // `FlutterGemma.getActiveModel()` no devuelve una instancia compartida:
    // cada llamada carga un modelo nuevo (ver su propia implementación). Sin
    // cerrarlo después, cada «Generar con IA» dejaba un modelo entero sin
    // liberar en memoria, y el siguiente intento competía por los mismos
    // recursos — eso es lo que hacía que la generación nunca terminara.
    InferenceModel? modelo;
    try {
      // 1024 en vez de 768: la rutina generada (varios pasos, cada uno con
      // su propio texto) no siempre cabía en la ventana anterior junto con
      // la instrucción de sistema y la petición.
      modelo = await FlutterGemma.getActiveModel(maxTokens: 1024);
      final chat = await modelo.createChat(
        systemInstruction: instruccionSistema,
        maxOutputTokens: 350,
        temperature: 0.6,
        // Mismo problema que en el chat conversacional (ConversadorGemma):
        // `topK: 1` por defecto es decodificación greedy, la causa más
        // probable de que el JSON generado saliera mal formado o repetitivo
        // y `_parsearRutinaGenerada`/`_parsearPlatosGenerados` lo descartaran.
        topK: 40,
        topP: 0.9,
      );
      await chat.addQuery(Message.text(text: peticion, isUser: true));
      // Mismo riesgo que tenía el chat antes de arreglarlo: sin tope, un
      // cuelgue del motor nativo a media generación dejaba "Generando..."
      // esperando para siempre.
      final respuesta = await chat
          .generateChatResponse()
          .timeout(_tiempoMaximoGeneracion);
      return switch (respuesta) {
        TextResponse(:final token) =>
          token.trim().isEmpty ? null : token.trim(),
        _ => null,
      };
    } catch (_) {
      // Sin modelo listo, error del plugin nativo, colgado, lo que sea: se
      // traduce en null y quien llama cae al catálogo de respaldo (sección
      // 4.3, 4.5).
      return null;
    } finally {
      await modelo?.close();
    }
  }
}
