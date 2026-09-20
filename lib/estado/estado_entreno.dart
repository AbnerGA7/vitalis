/// Estado del reproductor de entrenamiento. Sección 4.5 · RF-43…RF-45, RF-60,
/// RF-61, RNF-06.
///
/// El cronómetro vive en el dominio y es puro; aquí solo se le pregunta la
/// hora real y se disparan las señales de cada canal.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dominio/logica/cronometro.dart';
import '../dominio/logica/senales.dart';
import '../dominio/modelos/enums.dart';
import '../dominio/modelos/rutina.dart';
import '../servicios/contratos/contratos.dart';
import 'notificador_app.dart';
import 'proveedores.dart';

/// Con qué frecuencia se vuelve a preguntar la hora al reloj.
///
/// No cuenta ticks: solo provoca el repintado. El tiempo sale siempre de la
/// diferencia con el instante de inicio de fase (RNF-06).
const Duration periodoRefresco = Duration(milliseconds: 200);

class EstadoEntreno {
  const EstadoEntreno({
    this.cronometro,
    required this.ahora,
    this.destellando = false,
  });

  final EstadoCronometro? cronometro;

  /// Instante del último refresco; hace de reloj para la interfaz.
  final DateTime ahora;

  /// Destello verde de fin de descanso, 2,4 s (RF-60).
  final bool destellando;

  bool get activo => cronometro != null;

  bool get terminado => cronometro?.terminado ?? false;

  int get restanteS => cronometro?.restanteS(ahora) ?? 0;

  EstadoEntreno copiarCon({
    EstadoCronometro? cronometro,
    bool limpiarCronometro = false,
    DateTime? ahora,
    bool? destellando,
  }) =>
      EstadoEntreno(
        cronometro: limpiarCronometro ? null : (cronometro ?? this.cronometro),
        ahora: ahora ?? this.ahora,
        destellando: destellando ?? this.destellando,
      );
}

class NotificadorEntreno extends Notifier<EstadoEntreno> {
  Timer? _refresco;
  Timer? _finDestello;
  bool _vivo = true;
  int _ultimoT3 = -1;

  @override
  EstadoEntreno build() {
    ref.onDispose(() {
      _vivo = false;
      _refresco?.cancel();
      _finDestello?.cancel();
    });
    return EstadoEntreno(ahora: ref.read(relojProvider).ahora());
  }

  Reloj get _reloj => ref.read(relojProvider);

  Haptico get _haptico => ref.read(hapticoProvider);

  /// ¿Ha declarado la persona que quiere avisos por vibración? (RF-61)
  bool get _vibracionDeclarada =>
      ref.read(estadoAppProvider).preferencias.vibracion;

  /// Avisos de fase: solo para quien los ha pedido, para no sorprender a nadie.
  void _vibrarAviso(Future<void> Function() patron) {
    if (_vibracionDeclarada) unawaited(patron());
  }

  Anunciador get _anunciador => ref.read(anunciadorProvider);

  /// Abre el reproductor con una rutina (RF-43).
  void empezar(Rutina rutina) {
    final ahora = _reloj.ahora();
    _ultimoT3 = -1;
    state = EstadoEntreno(
      cronometro: EstadoCronometro.iniciar(rutina, ahora),
      ahora: ahora,
    );
    _anunciarFase(inicio: true);
    _vibrarAviso(_haptico.inicioFase);
    _refresco?.cancel();
    _refresco = Timer.periodic(periodoRefresco, (_) => _latido());
  }

  /// Cierra el reproductor, guardando lo avanzado.
  Future<void> salir({bool completada = false}) async {
    final cronometro = state.cronometro;
    _refresco?.cancel();
    _refresco = null;
    _finDestello?.cancel();
    if (cronometro != null) {
      await ref.read(almacenProvider).guardarSesion(
            SesionEntreno(
              rutinaId: cronometro.rutina.id,
              fecha: ref.read(estadoAppProvider).dia,
              completada: completada || cronometro.terminado,
              pasoActual: cronometro.numeroPaso,
            ),
          );
      ref.invalidate(sesionesProvider);
    }
    if (!_vivo) return;
    state = state.copiarCon(limpiarCronometro: true, destellando: false);
  }

  void _latido() {
    final cronometro = state.cronometro;
    if (cronometro == null || !_vivo) return;
    final ahora = _reloj.ahora();

    // Vibración tres segundos antes del final (RF-61); su gemela visual es la
    // propia cuenta atrás, que nunca desaparece de pantalla (AC-12).
    if (cronometro.esT3(ahora) && _ultimoT3 != cronometro.indicePaso) {
      _ultimoT3 = cronometro.indicePaso;
      _vibrarAviso(_haptico.tresSegundos);
    }

    final avanzado = cronometro.avanzarSiVencio(ahora);
    if (identical(avanzado, cronometro)) {
      state = state.copiarCon(ahora: ahora);
      return;
    }

    // La fase ha vencido sola.
    final eraDescanso = cronometro.paso.tipo == TipoPaso.descanso;
    state = state.copiarCon(cronometro: avanzado, ahora: ahora);
    _ultimoT3 = -1;
    _vibrarAviso(_haptico.finFase);

    if (avanzado.terminado) {
      _anunciador.anunciar(
        'Entrenamiento terminado. ${cronometro.rutina.nombre} completada.',
        prioridad: PrioridadAnuncio.cortes,
      );
      unawaited(salir(completada: true));
      return;
    }

    if (eraDescanso) {
      // La señal de fin de descanso es obligatoria y no sonora (RF-45), la
      // haya declarado quien la haya declarado. Su gemela visual es el cambio
      // de fase, que siempre se ve (AC-12).
      if (!_vibracionDeclarada) unawaited(_haptico.finFase());
      // Además, el destello verde para quien no oye (RF-60).
      if (ref.read(estadoAppProvider).preferencias.subtitulos) _destellar();
    }
    _anunciarFase();
  }

  void _destellar() {
    _finDestello?.cancel();
    state = state.copiarCon(destellando: true);
    _finDestello = Timer(duracionDestello, () {
      if (!_vivo) return;
      state = state.copiarCon(destellando: false);
    });
  }

  void _cancelarDestello() {
    _finDestello?.cancel();
    if (state.destellando) state = state.copiarCon(destellando: false);
  }

  /// Anuncia el siguiente ejercicio por lector de pantalla antes de empezar
  /// (RF-61).
  void _anunciarFase({bool inicio = false}) {
    final cronometro = state.cronometro;
    if (cronometro == null) return;
    final paso = cronometro.paso;
    final prefijo = inicio ? 'Empieza ' : '';
    final texto = paso.tipo == TipoPaso.trabajo
        ? '$prefijo${paso.nombre}, ${paso.duracionS} segundos. '
            '${paso.indicacion}'
        : 'Descanso de ${paso.duracionS} segundos. ${paso.detalle}';
    _anunciador.anunciar(texto, prioridad: PrioridadAnuncio.cortes);
  }

  void pausar() {
    final cronometro = state.cronometro;
    if (cronometro == null) return;
    state = state.copiarCon(cronometro: cronometro.pausar(_reloj.ahora()));
    _anunciador.anunciar('En pausa');
  }

  void reanudar() {
    final cronometro = state.cronometro;
    if (cronometro == null) return;
    state = state.copiarCon(cronometro: cronometro.reanudar(_reloj.ahora()));
    _anunciador.anunciar('Reanudado');
  }

  /// Saltar paso reinicia la duración del destino y cancela destellos.
  void siguiente() {
    final cronometro = state.cronometro;
    if (cronometro == null) return;
    _cancelarDestello();
    _ultimoT3 = -1;
    final avanzado = cronometro.siguiente(_reloj.ahora());
    state = state.copiarCon(cronometro: avanzado, ahora: _reloj.ahora());
    if (avanzado.terminado) {
      unawaited(salir(completada: true));
      return;
    }
    _anunciarFase();
  }

  void anterior() {
    final cronometro = state.cronometro;
    if (cronometro == null) return;
    _cancelarDestello();
    _ultimoT3 = -1;
    state = state.copiarCon(
      cronometro: cronometro.anterior(_reloj.ahora()),
      ahora: _reloj.ahora(),
    );
    _anunciarFase();
  }
}

final entrenoProvider =
    NotifierProvider<NotificadorEntreno, EstadoEntreno>(NotificadorEntreno.new);

/// Sesiones guardadas, para el resumen semanal (RF-42).
final sesionesProvider = FutureProvider<List<SesionEntreno>>(
  (ref) => ref.watch(almacenProvider).leerSesiones(),
);
