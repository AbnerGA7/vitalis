/// Dictado con el servicio de voz del sistema. ADR-04 · RF-10, RF-11.
///
/// Decisión para v1: se usa el reconocedor del sistema forzando el modo
/// en dispositivo (`onDevice: true`), de forma que el audio no sale del
/// teléfono (RNF-01, RNF-09). Si el dispositivo no ofrece reconocimiento
/// local, [disponible] devuelve false y la interfaz se queda solo con texto,
/// que es la alternativa que exige AC-11.
library;

import 'dart:async';

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

  /// Locale español elegido de entre los que el propio dispositivo tiene
  /// instalados para reconocimiento en el dispositivo. `null` si no hay
  /// ninguno: en ese caso se deja que el reconocedor use su locale de
  /// sistema por defecto en vez de forzar uno.
  String? _localeElegido;

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
      if (_iniciado) _localeElegido = await _elegirLocale();
    } on Exception {
      _iniciado = false;
    }
    return _iniciado;
  }

  /// Pedir un locale que el teléfono no tiene descargado (p. ej. forzar
  /// «es_ES» en un equipo que solo trae «es-US») hace que el reconocedor
  /// falle con `LANGUAGE_PACK_ERROR` sin dictar una sola palabra. En vez de
  /// forzar uno fijo, se elige entre los que el propio dispositivo reporta
  /// como disponibles: preferentemente español de Perú, si no cualquier
  /// español, y si no hay ninguno, se deja que decida el sistema.
  Future<String?> _elegirLocale() async {
    List<LocaleName> disponibles;
    try {
      disponibles = await _motor.locales();
    } on Exception {
      return null;
    }
    LocaleName? algunEspanol;
    for (final locale in disponibles) {
      final id = locale.localeId.toLowerCase();
      if (!id.startsWith('es')) continue;
      if (id.contains('pe')) return locale.localeId;
      algunEspanol ??= locale;
    }
    return algunEspanol?.localeId;
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
        onResult: (resultado) {
          final transcripcion = Transcripcion(
            texto: resultado.recognizedWords,
            definitiva: resultado.finalResult,
          );
          if (transcripcion.definitiva) {
            _temporizadorCierre?.cancel();
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
          localeId: _localeElegido,
          // Un error transitorio (p. ej. un instante sin habla detectada) no
          // debe abortar el turno entero: se deja que `pauseFor`, o el
          // temporizador de respaldo de abajo, lo cierren con normalidad en
          // vez de mandar a la persona directo al mensaje de error.
          cancelOnError: false,
          pauseFor: _pausaFinal,
          listenFor: const Duration(seconds: 30),
        ),
      );
    } on Exception catch (error) {
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
      alTranscribir(Transcripcion(texto: parcial.texto, definitiva: true));
    });
  }

  @override
  Future<void> detener() async {
    _temporizadorCierre?.cancel();
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
