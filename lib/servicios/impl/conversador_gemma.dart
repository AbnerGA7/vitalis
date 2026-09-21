/// Conversación real contra el modelo de lenguaje local. ADR-03.
///
/// Envuelve flutter_gemma (motor MediaPipe, ficheros `.task`). No abre
/// ninguna conexión: todo el cálculo ocurre en el dispositivo (RNF-01).
library;

import 'dart:async';

import 'package:flutter_gemma/flutter_gemma.dart';

import '../contratos/contratos.dart';

/// Silencio máximo entre tokens antes de dar la generación por colgada.
///
/// El motor MediaPipe (.task) no aplica ningún tope de tokens de salida a
/// nivel de sesión — lo ignora con un aviso en el log, es una limitación
/// documentada del propio plugin — así que un `maxOutputTokens` fijo en
/// `createChat` no sirve de nada aquí. Detectar el atasco por *silencio
/// entre tokens* (en vez de un único plazo para toda la respuesta) además
/// reacciona antes: si el modelo sigue produciendo texto, cada hueco es
/// pequeño; si se cuelga a media generación, este plazo salta enseguida en
/// vez de esperar a que se cumpla un plazo fijo pensado para el peor caso.
const Duration _silencioMaximoEntreTokens = Duration(seconds: 12);

/// Tope de caracteres de una respuesta, para lo mismo que el `maxOutputTokens`
/// que el motor ignora: sin él, una respuesta que no colgó pero tampoco para
/// de generar (o que ignora la instrucción de ser breve) no tendría límite.
///
/// Es un tope duro de seguridad, no el punto normal de corte: ver
/// [_longitudBlandaRespuesta].
const int _longitudMaximaRespuesta = 640;

/// A partir de aquí, la respuesta ya dijo lo suficiente: en cuanto el
/// siguiente fragmento cierra una frase (`.`, `!`, `?`, `…`), se corta ahí en
/// vez de seguir hasta el tope duro. Evita que una respuesta válida se corte
/// a media frase solo porque llegó justo al límite de caracteres.
const int _longitudBlandaRespuesta = 420;

/// Caracteres que marcan un cierre de frase válido para el corte blando.
const List<String> _cierresDeFrase = ['.', '!', '?', '…'];

class ConversadorGemma implements ConversadorIA {
  InferenceModel? _modelo;
  InferenceChat? _chat;

  @override
  Future<void> reiniciar({required String instruccionSistema}) async {
    await _modelo?.close();
    // Ventana de contexto algo más pequeña que el máximo por defecto (1024):
    // la conversación de Inicio es corta y efímera (RF-16). 512 en vez de
    // 256 dejaba muy poco margen antes de que el propio motor empezara a
    // olvidar los primeros turnos (recorta historial en cuanto se acerca al
    // límite), lo que hacía perder el hilo a las pocas frases.
    _modelo = await FlutterGemma.getActiveModel(maxTokens: 1024);
    _chat = await _modelo!.createChat(
      systemInstruction: instruccionSistema,
      temperature: 0.7,
      // El motor usa `topK: 1` por defecto, es decir, decodificación
      // «greedy»: siempre el token más probable, sin variación. En un
      // modelo tan pequeño eso es justo lo que produce bucles de
      // repetición y respuestas planas o inconexas. Con `topK`/`topP` se
      // muestrea entre las opciones razonables en vez de una sola.
      topK: 40,
      topP: 0.92,
      // Semilla distinta en cada reinicio de conversación; con la semilla
      // fija por defecto, dos conversaciones con un contexto parecido
      // sonarían idénticas.
      randomSeed: DateTime.now().microsecondsSinceEpoch % 1000000,
    );
  }

  @override
  Future<String> responder(String texto) async {
    final chat = _chat;
    if (chat == null) {
      throw StateError('Llama a reiniciar() antes de responder().');
    }
    await chat.addQuery(Message.text(text: texto, isUser: true));

    final buffer = StringBuffer();
    try {
      await for (final fragmento in chat
          .generateChatResponseAsync()
          .timeout(_silencioMaximoEntreTokens)) {
        if (fragmento is TextResponse) {
          buffer.write(fragmento.token);
          // Al cortar aquí, el `break` cancela la suscripción al stream y con
          // ella la generación en curso: no sigue trabajando en segundo plano
          // por una respuesta que ya no se va a usar entera.
          if (buffer.length >= _longitudMaximaRespuesta) break;
          if (buffer.length >= _longitudBlandaRespuesta &&
              _cierresDeFrase.any(fragmento.token.trimRight().endsWith)) {
            break;
          }
        }
      }
    } on TimeoutException {
      // Si ya hay algo de texto, una respuesta a medias es mejor que
      // ninguna. Si el atasco fue desde el primer token, no hay nada que
      // devolver: se relanza para que MotorIAHibrido caiga a las reglas.
      if (buffer.isEmpty) rethrow;
    }

    final respuesta = buffer.toString().trim();
    return respuesta.isEmpty
        ? 'No se me ocurre nada que añadir a eso.'
        : respuesta;
  }
}
