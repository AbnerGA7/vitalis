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
    this.modoVozContinua = false,
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

  /// Chat de voz manos-libres: tras hablar la respuesta, se reabre el
  /// dictado solo, sin que la persona tenga que volver a tocar el micro.
  /// Se activa al tocar el micro y se apaga al tocarlo de nuevo mientras
  /// escucha, o al escribir (RF-10, RF-11).
  final bool modoVozContinua;

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
    bool? modoVozContinua,
  }) =>
      EstadoConversacion(
        mensajes: mensajes ?? this.mensajes,
        fase: fase ?? this.fase,
        borrador: borrador ?? this.borrador,
        pasoPensando: pasoPensando ?? this.pasoPensando,
        errorVoz: limpiarError ? null : (errorVoz ?? this.errorVoz),
        vozDisponible: vozDisponible ?? this.vozDisponible,
        modoVozContinua: modoVozContinua ?? this.modoVozContinua,
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
    // Escribir a mano gana sobre el chat de voz manos-libres: si la persona
    // prefiere teclear, se corta el dictado y no se reabre solo después. Se
    // apaga el modo ya mismo (no tras el `await` de detenerDictado) para que
    // el estado quede consistente en el mismo tick que la persona escribió.
    if (state.escuchando || state.modoVozContinua) {
      state = state.copiarCon(modoVozContinua: false);
      unawaited(detenerDictado());
    }
    state = state.copiarCon(borrador: texto, limpiarError: true);
  }

  /// Envía lo que hay en el campo, venga del teclado o del dictado (RF-10).
  ///
  /// [porVoz] evita el retraso artificial de los pasos de «pensando»: en el
  /// chat de voz esa espera se suma a la de la propia inferencia local, y ahí
  /// cada milisegundo se nota.
  Future<void> enviar([String? texto, bool porVoz = false]) async {
    final contenido = (texto ?? state.borrador).trim();
    if (contenido.isEmpty) return;
    // Sin este guard, un segundo turno (p. ej. otro tramo dictado mientras el
    // anterior seguía «pensando») lanzaba una llamada nueva al modelo encima
    // de la que ya estaba en curso, y como el motor solo sirve una
    // generación a la vez, las siguientes se quedaban esperando en fila
    // detrás de la primera sin que nada volviera a responder.
    if (state.fase == FaseAsistente.pensando) return;

    await detenerDictado();

    state = state.copiarCon(
      mensajes: [...state.mensajes, Mensaje.persona(contenido)],
      borrador: '',
      fase: FaseAsistente.pensando,
      pasoPensando: 'Entendiendo lo que me pides',
      limpiarError: true,
    );
    _anunciador.anunciar('Pensando', prioridad: PrioridadAnuncio.cortes);

    if (!porVoz) {
      await Future<void>.delayed(pausaEntrePasosGeneracion);
      state = state.copiarCon(pasoPensando: 'Mirando tu perfil');
    }

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
    // la voz es un añadido, el texto ya está en pantalla. Si el turno vino
    // por voz y el modo manos-libres sigue activo, en cuanto termine de
    // hablar se reabre el dictado solo (ver _hablarYSeguirEscuchando).
    unawaited(_hablarYSeguirEscuchando(respuesta.texto, porVoz: porVoz));
  }

  Future<void> _hablar(String texto) async {
    try {
      // Tope de tiempo también aquí: el modo manos-libres espera a que
      // termine de hablar para volver a escuchar (_hablarYSeguirEscuchando),
      // así que un motor de TTS colgado dejaría el micro sin reabrirse
      // nunca, en silencio, sin ningún aviso.
      await ref
          .read(sintesisVozProvider)
          .hablar(texto)
          .timeout(const Duration(seconds: 20));
    } on Exception {
      // La respuesta ya está en pantalla y anunciada al lector; si falla la
      // voz (o se cuelga), no hay por qué interrumpir la conversación.
    }
  }

  /// Manos-libres (RF-10, RF-11): un turno por voz reabre el dictado solo al
  /// terminar de hablar, sin que la persona tenga que volver a tocar el
  /// micro para seguir la conversación. Se corta si mientras tanto se
  /// desactivó el modo (p. ej. porque la persona se puso a escribir).
  Future<void> _hablarYSeguirEscuchando(
    String texto, {
    required bool porVoz,
  }) async {
    await _hablar(texto);
    if (!_vivo || !porVoz || !state.modoVozContinua) return;
    await iniciarDictado();
  }

  /// Arranca el dictado. La transcripción en vivo sirve de subtítulo (RF-11).
  Future<void> iniciarDictado() async {
    if (state.escuchando) {
      await detenerDictado(porUsuario: true);
      return;
    }
    // Vibración al abrir y cerrar el dictado (AC-08).
    await ref.read(hapticoProvider).confirmacion();

    state = state.copiarCon(
      fase: FaseAsistente.escuchando,
      modoVozContinua: true,
      limpiarError: true,
    );
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
          unawaited(enviar(transcripcion.texto, true));
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

  /// [porUsuario] apaga también el modo de voz continua (RF-10, RF-11): es
  /// lo que distingue a la persona parando el dictado a propósito (o
  /// poniéndose a escribir) del corte interno que hace `enviar()` antes de
  /// mandar cada turno, que no debe cancelar el manos-libres.
  Future<void> detenerDictado({bool porUsuario = false}) async {
    if (state.escuchando) {
      await ref.read(hapticoProvider).confirmacion();
      await _voz.detener();
      if (!_vivo) return;
      state = state.copiarCon(fase: FaseAsistente.reposo);
    }
    if (porUsuario && state.modoVozContinua) {
      state = state.copiarCon(modoVozContinua: false);
    }
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
