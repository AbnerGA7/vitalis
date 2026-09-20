/// Voz de salida sobre el motor de TTS del sistema. RNF-01, RNF-09.
///
/// Offline en Android e iOS: usa la voz ya instalada en el teléfono, no
/// descarga ni envía nada.
library;

import 'package:flutter_tts/flutter_tts.dart';

import '../contratos/contratos.dart';

class SintesisVozSistema implements SintesisVoz {
  SintesisVozSistema({FlutterTts? motor}) : _motor = motor ?? FlutterTts() {
    _motor.setStartHandler(() => _hablando = true);
    _motor.setCompletionHandler(() => _hablando = false);
    _motor.setCancelHandler(() => _hablando = false);
    _motor.setErrorHandler((_) => _hablando = false);
    // Habla una frase entera antes de devolver el control: así se puede
    // encadenar sin solaparse con la siguiente respuesta.
    _motor.awaitSpeakCompletion(true);
    _motor.setLanguage('es-ES');
    _motor.setSpeechRate(0.5);
  }

  final FlutterTts _motor;
  bool _hablando = false;

  @override
  bool get hablando => _hablando;

  @override
  Future<void> hablar(String texto) async {
    if (texto.trim().isEmpty) return;
    await detener();
    await _motor.speak(texto);
  }

  @override
  Future<void> detener() async {
    if (_hablando) await _motor.stop();
  }
}

/// Voz de salida silenciosa: no habla. Útil en pruebas y si la persona
/// desactiva la voz.
class SintesisVozSilenciosa implements SintesisVoz {
  const SintesisVozSilenciosa();

  @override
  bool get hablando => false;

  @override
  Future<void> hablar(String texto) async {}

  @override
  Future<void> detener() async {}
}
