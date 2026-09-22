/// Conversación con el asistente. Sección 3 · Inicio.
///
/// Es efímera: arranca vacía cada día y nunca se guarda (RF-16).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dominio/modelos/enums.dart';
import '../dominio/modelos/mensaje.dart';
import '../servicios/contratos/contratos.dart';
import '../servicios/impl/motor_ia_hibrido.dart';
import 'notificador_app.dart';
import 'proveedores.dart';

/// Estados del asistente en Inicio (sección 3).
enum FaseAsistente { reposo, escuchando, pensando, respondido }

/// Caracteres que marcan un cierre de frase válido para ir hablando la
/// respuesta por partes en cuanto cada una está completa (mismo criterio que
/// [ConversadorGemma] al cortar la generación).
const List<String> _cierresDeFrase = ['.', '!', '?', '…'];

/// Índice justo después del último cierre de frase en [texto], o `null` si
/// todavía no hay ninguna frase cerrada.
int? _finDeUltimaFraseCerrada(String texto) {
  var mejor = -1;
  for (final cierre in _cierresDeFrase) {
    final indice = texto.lastIndexOf(cierre);
    if (indice > mejor) mejor = indice;
  }
  return mejor == -1 ? null : mejor + 1;
}

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

  /// Cierra la ventana de carrera entre el guard de [enviar] y el momento en
  /// que `state.fase` pasa de verdad a `pensando`: ese cambio llega después
  /// de `await detenerDictado()`, así que dos llamadas casi simultáneas (dos
  /// tramos dictados seguidos, un doble toque en enviar) leían las dos la
  /// fase todavía en reposo y las dos arrancaban su propia llamada al
  /// modelo. Se marca en el mismo tick que se hace el guard, antes de
  /// cualquier `await`.
  bool _entrandoAPensar = false;

  @override
  EstadoConversacion build() {
    ref.onDispose(() => _vivo = false);
    // Se comprueba al entrar si hay dictado; si no lo hay, la interfaz se
    // queda solo con texto, que es la alternativa que exige AC-11.
    Future<void>(() async {
      // Comprobar `_vivo` antes de tocar `ref`, no solo antes de escribir el
      // estado: si el notificador se destruye antes de que arranque esta
      // tarea (posible en cuanto se planifica con `Future(...)`, que no
      // corre de forma síncrona), `ref.read` lanza porque el contenedor ya
      // está destruido.
      if (!_vivo) return;
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
  ///
  /// La respuesta llega en streaming (RF-13): el mensaje del asistente se va
  /// actualizando fragmento a fragmento en vez de aparecer entero al final,
  /// y cada frase que se completa se dice en voz alta sin esperar a que
  /// termine de generarse toda la respuesta.
  Future<void> enviar([String? texto, bool porVoz = false]) async {
    final contenido = (texto ?? state.borrador).trim();
    if (contenido.isEmpty) return;
    // Sin este guard, un segundo turno (p. ej. otro tramo dictado mientras el
    // anterior seguía «pensando») lanzaba una llamada nueva al modelo encima
    // de la que ya estaba en curso, y como el motor solo sirve una
    // generación a la vez, las siguientes se quedaban esperando en fila
    // detrás de la primera sin que nada volviera a responder.
    if (state.fase == FaseAsistente.pensando || _entrandoAPensar) return;
    _entrandoAPensar = true;

    try {
      await detenerDictado();

      state = state.copiarCon(
        mensajes: [...state.mensajes, Mensaje.persona(contenido)],
        borrador: '',
        fase: FaseAsistente.pensando,
        pasoPensando: 'Entendiendo lo que me pides',
        limpiarError: true,
      );
    } finally {
      _entrandoAPensar = false;
    }
    _anunciador.anunciar('Pensando', prioridad: PrioridadAnuncio.cortes);

    if (!porVoz) {
      await Future<void>.delayed(pausaEntrePasosGeneracion);
      state = state.copiarCon(pasoPensando: 'Mirando tu perfil');
    }

    var vocalizado = '';
    var huboMensaje = false;
    Future<void>? colaVoz;
    var ultima = const RespuestaAsistente(
      intencion: Intencion.desconocida,
      texto: '',
    );

    void hablarEnCola(String fragmentoDeTexto) {
      final previa = colaVoz;
      colaVoz = previa == null
          ? _hablar(fragmentoDeTexto)
          : previa.then((_) => _continuarHablando(fragmentoDeTexto));
    }

    await for (final fragmento in _motor.responderEnVivo(contenido)) {
      if (!_vivo) return;
      ultima = fragmento;

      final mensaje = Mensaje(
        autor: Autor.asistente,
        texto: fragmento.texto,
        tipo: Mensaje.tipoDeIntencion(
          fragmento.intencion,
          esConversacionLibre: fragmento.esConversacionLibre,
        ),
        plan: fragmento.plan,
        ejemplos: fragmento.ejemplos,
      );
      state = state.copiarCon(
        mensajes: [
          ...huboMensaje
              ? state.mensajes.sublist(0, state.mensajes.length - 1)
              : state.mensajes,
          mensaje,
        ],
        fase: FaseAsistente.respondido,
        pasoPensando: '',
      );
      huboMensaje = true;

      if (!fragmento.texto.startsWith(vocalizado)) {
        // El texto no es continuación de lo ya dicho (p. ej. se reemplazó
        // entero por la corrección de tono de MotorIAHibrido): se habla de
        // cero, interrumpiendo lo que estuviera sonando.
        vocalizado = '';
        colaVoz = null;
      }
      final cierre = _finDeUltimaFraseCerrada(fragmento.texto);
      if (cierre != null && cierre > vocalizado.length) {
        final frase =
            fragmento.texto.substring(vocalizado.length, cierre).trim();
        vocalizado = fragmento.texto.substring(0, cierre);
        if (frase.isNotEmpty) hablarEnCola(frase);
      }
    }
    if (!_vivo) return;

    _anunciador.anunciar(ultima.texto, prioridad: PrioridadAnuncio.cortes);

    final cola = ultima.texto.startsWith(vocalizado)
        ? ultima.texto.substring(vocalizado.length).trim()
        : ultima.texto;
    if (cola.isNotEmpty) hablarEnCola(cola);

    // El chat de voz no espera a que termine de hablar para seguir usable:
    // la voz es un añadido, el texto ya está en pantalla. Si el turno vino
    // por voz y el modo manos-libres sigue activo, en cuanto termine de
    // decir toda la respuesta se reabre el dictado solo.
    unawaited(_seguirEscuchandoTrasHablar(colaVoz, porVoz: porVoz));
  }

  Future<void> _hablar(String texto) async {
    try {
      // Tope de tiempo también aquí: el modo manos-libres espera a que
      // termine de hablar para volver a escuchar (_seguirEscuchandoTrasHablar),
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

  /// Como [_hablar], pero para encadenar la siguiente frase de la misma
  /// respuesta sin cortar la anterior a medias (RF-11, chat de voz).
  Future<void> _continuarHablando(String texto) async {
    try {
      await ref
          .read(sintesisVozProvider)
          .continuar(texto)
          .timeout(const Duration(seconds: 20));
    } on Exception {
      // Mismo motivo que en _hablar.
    }
  }

  /// Manos-libres (RF-10, RF-11): un turno por voz reabre el dictado solo al
  /// terminar de decir toda la respuesta (todas las frases encoladas, no
  /// cada una suelta), sin que la persona tenga que volver a tocar el micro
  /// para seguir la conversación. Se corta si mientras tanto se desactivó el
  /// modo (p. ej. porque la persona se puso a escribir).
  Future<void> _seguirEscuchandoTrasHablar(
    Future<void>? colaVoz, {
    required bool porVoz,
  }) async {
    await colaVoz;
    if (!_vivo || !porVoz || !state.modoVozContinua) return;
    await iniciarDictado();
  }

  /// Arranca el dictado. La transcripción en vivo sirve de subtítulo (RF-11).
  Future<void> iniciarDictado() async {
    if (state.escuchando) {
      await detenerDictado(porUsuario: true);
      return;
    }
    // Mientras se está esperando la respuesta, abrir el micro pisaría la fase
    // `pensando`: cuando la respuesta llegara, el guardado final la volvería
    // a tapar sin haber cerrado nunca el dictado que se acababa de abrir, y
    // el micro se quedaría escuchando de verdad sin ninguna señal en pantalla.
    if (state.fase == FaseAsistente.pensando) return;
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
        // Sin apagar también el modo manos-libres aquí, `modoVozContinua`
        // se quedaba en `true` aunque ya no hubiera nada escuchando: el
        // estado decía "modo continuo activo" sobre un dictado que en
        // realidad había fallado y no se iba a reabrir solo.
        state = state.copiarCon(
          fase: FaseAsistente.reposo,
          modoVozContinua: false,
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
