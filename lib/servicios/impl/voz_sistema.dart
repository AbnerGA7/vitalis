/// Dictado con el servicio de voz del sistema. ADR-04 · RF-10, RF-11.
///
/// Decisión para v1: se usa el reconocedor del sistema forzando el modo
/// en dispositivo (`onDevice: true`), de forma que el audio no sale del
/// teléfono (RNF-01, RNF-09). Si el dispositivo no ofrece reconocimiento
/// local, [disponible] devuelve false y la interfaz se queda solo con texto,
/// que es la alternativa que exige AC-11.
library;

import 'package:speech_to_text/speech_to_text.dart';

import '../contratos/contratos.dart';

class VozSistema implements Voz {
  VozSistema({SpeechToText? motor}) : _motor = motor ?? SpeechToText();

  static const String _localeEspanol = 'es_ES';

  final SpeechToText _motor;
  bool _iniciado = false;

  @override
  bool get escuchando => _motor.isListening;

  @override
  Future<bool> disponible() async {
    if (_iniciado) return true;
    try {
      _iniciado = await _motor.initialize(
        onError: (_) {},
        onStatus: (_) {},
      );
    } on Exception {
      _iniciado = false;
    }
    return _iniciado;
  }

  @override
  Future<void> escuchar({
    required void Function(Transcripcion) alTranscribir,
    required void Function(Object error) alFallar,
  }) async {
    if (!await disponible()) {
      alFallar(
        StateError('Este dispositivo no ofrece dictado sin conexión.'),
      );
      return;
    }
    try {
      await _motor.listen(
        onResult: (resultado) => alTranscribir(
          Transcripcion(
            texto: resultado.recognizedWords,
            definitiva: resultado.finalResult,
          ),
        ),
        listenOptions: SpeechListenOptions(
          // El reconocimiento nunca sale del dispositivo.
          onDevice: true,
          partialResults: true,
          listenMode: ListenMode.dictation,
          localeId: _localeEspanol,
          cancelOnError: true,
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 30),
        ),
      );
    } on Exception catch (error) {
      alFallar(error);
    }
  }

  @override
  Future<void> detener() async {
    if (_motor.isListening) await _motor.stop();
  }
}

/// Voz no disponible: la interfaz se queda solo con el campo de texto.
///
/// Es lo que se usa en pruebas y en plataformas sin reconocedor local.
class VozNoDisponible implements Voz {
  const VozNoDisponible();

  @override
  bool get escuchando => false;

  @override
  Future<bool> disponible() async => false;

  @override
  Future<void> escuchar({
    required void Function(Transcripcion) alTranscribir,
    required void Function(Object error) alFallar,
  }) async {
    alFallar(StateError('El dictado no está disponible.'));
  }

  @override
  Future<void> detener() async {}
}
