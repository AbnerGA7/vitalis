/// Servicios de dispositivo: reloj, háptico y anunciador. Sección 8.
library;

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import '../contratos/contratos.dart';

/// Reloj del sistema. En pruebas se sustituye por uno simulado.
class RelojSistema implements Reloj {
  const RelojSistema();

  @override
  DateTime ahora() => DateTime.now();
}

/// Patrones hápticos sobre la háptica estándar de Flutter.
///
/// Los tres patrones se distinguen por intensidad para que se noten distintos
/// incluso en dispositivos con háptica limitada (riesgo de la sección 8).
class HapticoFlutter implements Haptico {
  const HapticoFlutter();

  @override
  Future<void> inicioFase() => HapticFeedback.mediumImpact();

  @override
  Future<void> tresSegundos() => HapticFeedback.selectionClick();

  @override
  Future<void> finFase() async {
    // Doble golpe fuerte: es la señal más importante del reproductor.
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 160));
    await HapticFeedback.heavyImpact();
  }

  @override
  Future<void> confirmacion() => HapticFeedback.lightImpact();
}

/// Anuncios al lector de pantalla del sistema (TalkBack, VoiceOver).
///
/// Es el canal para lo que no se deduce de un cambio de interfaz, como el
/// anuncio del siguiente ejercicio (RF-61). Los cambios de estado que sí
/// tienen reflejo visual se anuncian con `Semantics(liveRegion: true)`, que
/// en Android no interrumpe la cola de TalkBack.
class AnunciadorSemantics implements Anunciador {
  const AnunciadorSemantics();

  @override
  void anunciar(
    String mensaje, {
    PrioridadAnuncio prioridad = PrioridadAnuncio.educado,
  }) {
    if (mensaje.trim().isEmpty) return;
    final vista = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (vista == null) return;
    SemanticsService.sendAnnouncement(
      vista,
      mensaje,
      TextDirection.ltr,
      assertiveness: prioridad == PrioridadAnuncio.cortes
          ? Assertiveness.assertive
          : Assertiveness.polite,
    );
  }
}
