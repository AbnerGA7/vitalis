/// Conversación con el asistente. Sección 3 · Inicio.
///
/// Es efímera: arranca vacía cada día y nunca se guarda (RF-16).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dominio/modelos/mensaje.dart';
import '../servicios/contratos/contratos.dart';
import '../servicios/impl/motor_ia_hibrido.dart';
import 'notificador_app.dart';
import 'proveedores.dart';

/// Estados del asistente en Inicio (sección 3).
enum FaseAsistente { reposo, escuchando, pensando, respondido }

class EstadoConversacion {
  const EstadoConversacion({
    this.mensajes = const [],
    this.fase = FaseAsistente.reposo,
    this.borrador = '',
    this.pasoPensando = '',
    this.errorVoz,
    this.vozDisponible = false,
  });

  final List<Mensaje> mensajes;
  final FaseAsistente fase;

  /// Texto del campo. El micro rellena este mismo campo, editable antes de
  /// enviar (RF-10).
  final String borrador;

  /// Texto por pasos del estado «pensando» (RF-15).
  final String pasoPensando;

  final String? errorVoz;
  final bool vozDisponible;

  bool get vacia => mensajes.isEmpty;

  bool get escuchando => fase == FaseAsistente.escuchando;

  EstadoConversacion copiarCon({
    List<Mensaje>? mensajes,
    FaseAsistente? fase,
    String? borrador,
    String? pasoPensando,
    String? errorVoz,
    bool limpiarError = false,
    bool? vozDisponible,
  }) =>
      EstadoConversacion(
        mensajes: mensajes ?? this.mensajes,
        fase: fase ?? this.fase,
        borrador: borrador ?? this.borrador,
        pasoPensando: pasoPensando ?? this.pasoPensando,
        errorVoz: limpiarError ? null : (errorVoz ?? this.errorVoz),
        vozDisponible: vozDisponible ?? this.vozDisponible,
      );
}

class NotificadorConversacion extends Notifier<EstadoConversacion> {
  /// Riverpod no expone `mounted` en este `Ref`, así que lo llevamos a mano
  /// para no escribir en un notificador ya desechado tras un `await`.
  bool _vivo = true;

  @override
  EstadoConversacion build() {
    ref.onDispose(() => _vivo = false);
    // Se comprueba al entrar si hay dictado; si no lo hay, la interfaz se
    // queda solo con texto, que es la alternativa que exige AC-11.
    Future<void>(() async {
      final hay = await ref.read(vozProvider).disponible();
      if (_vivo) {
        state = state.copiarCon(vozDisponible: hay);
      }
    });
    return const EstadoConversacion();
  }

  Voz get _voz => ref.read(vozProvider);

  MotorIA get _motor => ref.read(motorIaProvider);

  Anunciador get _anunciador => ref.read(anunciadorProvider);

  void escribir(String texto) {
    state = state.copiarCon(borrador: texto, limpiarError: true);
  }

  /// Envía lo que hay en el campo, venga del teclado o del dictado (RF-10).
  Future<void> enviar([String? texto]) async {
    final contenido = (texto ?? state.borrador).trim();
    if (contenido.isEmpty) return;

    await detenerDictado();

    state = state.copiarCon(
      mensajes: [...state.mensajes, Mensaje.persona(contenido)],
      borrador: '',
      fase: FaseAsistente.pensando,
      pasoPensando: 'Entendiendo lo que me pides',
      limpiarError: true,
    );
    _anunciador.anunciar('Pensando', prioridad: PrioridadAnuncio.cortes);

    await Future<void>.delayed(pausaEntrePasosGeneracion);
    state = state.copiarCon(pasoPensando: 'Mirando tu perfil');

    final respuesta = await _motor.responder(contenido);
    if (!_vivo) return;

    final mensaje = Mensaje(
      autor: Autor.asistente,
      texto: respuesta.texto,
      tipo: Mensaje.tipoDeIntencion(
        respuesta.intencion,
        esConversacionLibre: respuesta.esConversacionLibre,
      ),
      plan: respuesta.plan,
      ejemplos: respuesta.ejemplos,
    );

    state = state.copiarCon(
      mensajes: [...state.mensajes, mensaje],
      fase: FaseAsistente.respondido,
      pasoPensando: '',
    );
    _anunciador.anunciar(respuesta.texto, prioridad: PrioridadAnuncio.cortes);
    // El chat de voz no espera a que termine de hablar para seguir usable:
    // la voz es un añadido, el texto ya está en pantalla.
    unawaited(_hablar(respuesta.texto));
  }

  Future<void> _hablar(String texto) async {
    try {
      await ref.read(sintesisVozProvider).hablar(texto);
    } on Exception {
      // La respuesta ya está en pantalla y anunciada al lector; si falla la
      // voz, no hay por qué interrumpir la conversación.
    }
  }

  /// Arranca el dictado. La transcripción en vivo sirve de subtítulo (RF-11).
  Future<void> iniciarDictado() async {
    if (state.escuchando) {
      await detenerDictado();
      return;
    }
    // Vibración al abrir y cerrar el dictado (AC-08).
    await ref.read(hapticoProvider).confirmacion();

    state = state.copiarCon(fase: FaseAsistente.escuchando, limpiarError: true);
    _anunciador.anunciar('Escuchando', prioridad: PrioridadAnuncio.cortes);

    await _voz.escuchar(
      alTranscribir: (transcripcion) {
        if (!_vivo) return;
        state = state.copiarCon(borrador: transcripcion.texto);
        if (transcripcion.definitiva && transcripcion.texto.trim().isNotEmpty) {
          // Cierra el turno enviando lo dictado sin esperar a que se pulse
          // enviar: así el micro funciona como un chat de voz completo
          // (hablas → responde → lo escuchas), no solo como dictado a un
          // campo de texto.
          unawaited(enviar(transcripcion.texto));
        }
      },
      alFallar: (error) {
        if (!_vivo) return;
        state = state.copiarCon(
          fase: FaseAsistente.reposo,
          errorVoz: 'No he podido usar el dictado. '
              'Puedes escribir tu mensaje en el campo de texto.',
        );
        _anunciador.anunciar(
          'El dictado no está disponible. Escribe tu mensaje.',
          prioridad: PrioridadAnuncio.cortes,
        );
      },
    );
  }

  Future<void> detenerDictado() async {
    if (!state.escuchando) return;
    await ref.read(hapticoProvider).confirmacion();
    await _voz.detener();
    if (!_vivo) return;
    state = state.copiarCon(fase: FaseAsistente.reposo);
  }

  /// La conversación arranca vacía cada día (RF-16).
  ///
  /// Si el motor híbrido tiene una conversación abierta con el modelo real,
  /// también se olvida: el contexto de un día no debe colarse en el
  /// siguiente.
  void vaciar() {
    final motor = _motor;
    if (motor is MotorIAHibrido) motor.reiniciarConversacion();
    state = EstadoConversacion(vozDisponible: state.vozDisponible);
  }
}

final conversacionProvider =
    NotifierProvider<NotificadorConversacion, EstadoConversacion>(
  NotificadorConversacion.new,
);
