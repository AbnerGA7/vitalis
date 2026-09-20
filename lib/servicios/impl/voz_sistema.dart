/// Dictado con el servicio de voz del sistema. ADR-04 · RF-10, RF-11.
///
/// Decisión para v1: se usa el reconocedor del sistema forzando el modo
/// en dispositivo (`onDevice: true`), de forma que el audio no sale del
/// teléfono (RNF-01, RNF-09). Si el dispositivo no ofrece reconocimiento
/// local, [disponible] devuelve false y la interfaz se queda solo con texto,
/// que es la alternativa que exige AC-11.
library;

import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../contratos/contratos.dart';

class VozSistema implements Voz {
  VozSistema({SpeechToText? motor}) : _motor = motor ?? SpeechToText();

  /// Silencio tras el que se da por cerrado el turno, tanto para el propio
  /// `pauseFor` del reconocedor como para el temporizador de respaldo.
  static const Duration _pausaFinal = Duration(seconds: 3);

  final SpeechToText _motor;
  bool _iniciado = false;
  Timer? _temporizadorCierre;

  /// El `alFallar` del `escuchar()` en curso. Los errores del reconocedor
  /// (p. ej. que el idioma configurado no tenga su paquete de datos
  /// descargado) no llegan como excepción de `listen()`: llegan de forma
  /// asíncrona al `onError` registrado en `initialize()`. Sin reenviarlos
  /// aquí, un fallo del motor dejaba el turno en «escuchando» para siempre,
  /// sin avisar a nadie ni mostrar ningún error.
  void Function(Object error)? _alFallarActual;

  @override
  bool get escuchando => _motor.isListening;

  @override
  Future<bool> disponible() async {
    if (_iniciado) return true;
    try {
      _iniciado = await _motor.initialize(
        onError: _alFallarDelMotor,
        onStatus: (_) {},
      );
    } on Exception {
      _iniciado = false;
    }
    return _iniciado;
  }

  /// Un solo disparo: se limpia justo antes de llamarlo, para que un error
  /// tardío del motor nativo (puede llegar después de que el turno ya
  /// terminara bien, es una condición de carrera real del propio
  /// reconocedor) no reactive el `alFallar` de un turno que ya se cerró sin
  /// problema.
  void _alFallarDelMotor(SpeechRecognitionError error) {
    _temporizadorCierre?.cancel();
    final alFallar = _alFallarActual;
    _alFallarActual = null;
    alFallar?.call(StateError(error.errorMsg));
  }

  @override
  Future<void> escuchar({
    required void Function(Transcripcion) alTranscribir,
    required void Function(Object error) alFallar,
  }) async {
    _alFallarActual = alFallar;
    if (!await disponible()) {
      _alFallarActual = null;
      alFallar(
        StateError('Este dispositivo no ofrece dictado sin conexión.'),
      );
      return;
    }
    try {
      await _motor.listen(
        onResult: (resultado) {
          final transcripcion = Transcripcion(
            texto: resultado.recognizedWords,
            definitiva: resultado.finalResult,
          );
          if (transcripcion.definitiva) {
            _temporizadorCierre?.cancel();
            // Turno cerrado con resultado: ya no hace falta reenviar un
            // error tardío de este motor a este `alFallar`.
            _alFallarActual = null;
          } else {
            _reprogramarCierreDeRespaldo(transcripcion, alTranscribir);
          }
          alTranscribir(transcripcion);
        },
        listenOptions: SpeechListenOptions(
          // El reconocimiento nunca sale del dispositivo.
          onDevice: true,
          partialResults: true,
          listenMode: ListenMode.dictation,
          // Sin locale fijo: forzar uno (p. ej. «es_ES») falla con
          // LANGUAGE_PACK_ERROR si el teléfono no tiene ese paquete de datos
          // descargado, aunque el idioma aparezca listado como «soportado».
          // Se deja que el reconocedor use el idioma de voz que ya tiene
          // configurado y funcionando en el resto del sistema.
          cancelOnError: false,
          pauseFor: _pausaFinal,
          listenFor: const Duration(seconds: 30),
        ),
      );
    } on Exception catch (error) {
      _alFallarActual = null;
      alFallar(error);
    }
  }

  /// Red de seguridad para el manos-libres: en algunos reconocedores Android,
  /// `finalResult` no siempre llega de forma fiable tras `pauseFor`. Si pasa
  /// ese mismo silencio sin una transcripción nueva y ya hay texto dictado,
  /// se cierra el turno a mano en vez de dejar a la persona esperando una
  /// respuesta que nunca llega.
  void _reprogramarCierreDeRespaldo(
    Transcripcion parcial,
    void Function(Transcripcion) alTranscribir,
  ) {
    _temporizadorCierre?.cancel();
    if (parcial.texto.trim().isEmpty) return;
    _temporizadorCierre = Timer(_pausaFinal, () async {
      if (!_motor.isListening) return;
      await _motor.stop();
      _alFallarActual = null;
      alTranscribir(Transcripcion(texto: parcial.texto, definitiva: true));
    });
  }

  @override
  Future<void> detener() async {
    _temporizadorCierre?.cancel();
    _alFallarActual = null;
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
