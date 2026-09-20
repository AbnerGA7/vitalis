/// Subtítulo y línea de vibración del reproductor. RF-60, RF-61, RF-62 ·
/// AC-08, AC-12.
///
/// Cada señal sonora tiene gemela en subtítulo y cada vibración tiene gemela
/// visual. Si están activas las dos necesidades, se apilan.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nocturne_tema.dart';
import '../../core/nocturne_tokens.dart';
import '../../dominio/logica/senales.dart';
import '../../dominio/modelos/enums.dart';
import '../../estado/estado_entreno.dart';
import '../../estado/notificador_app.dart';

class SenalesReproductor extends ConsumerWidget {
  const SenalesReproductor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencias =
        ref.watch(estadoAppProvider.select((estado) => estado.preferencias));
    if (!preferencias.subtitulos && !preferencias.vibracion) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(Espacio.l, 0, Espacio.l, 0),
      child: Column(
        children: [
          if (preferencias.subtitulos) const _Subtitulo(),
          if (preferencias.subtitulos && preferencias.vibracion)
            const SizedBox(height: Espacio.s),
          if (preferencias.vibracion) const _LineaVibracion(),
        ],
      ),
    );
  }
}

/// Subtítulo de toda señal sonora (RF-60).
class _Subtitulo extends ConsumerWidget {
  const _Subtitulo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final paleta = context.paleta;
    final entreno = ref.watch(entrenoProvider);
    final cronometro = entreno.cronometro;
    if (cronometro == null) return const SizedBox.shrink();

    final paso = cronometro.paso;
    final restante = cronometro.restanteS(entreno.ahora);

    final texto = switch (true) {
      _ when entreno.destellando => '[Señal de fin de descanso]',
      _ when cronometro.enPausa => '[En pausa]',
      _ when restante <= segundosAvisoPrevio =>
        '[Aviso: quedan $restante segundos]',
      _ when paso.tipo == TipoPaso.trabajo =>
        '[Trabajo] ${paso.nombre}. ${paso.indicacion}',
      _ => '[Descanso] ${paso.detalle}',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Espacio.m,
        vertical: Espacio.m,
      ),
      decoration: BoxDecoration(
        color: paleta.superficieAlta,
        borderRadius: BorderRadius.circular(radioTarjeta),
        border: Border.all(color: paleta.borde),
      ),
      child: Semantics(
        liveRegion: true,
        child: Text(
          texto,
          style: tema.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Gemela visual de la vibración: marca en qué momento vibra (AC-12).
class _LineaVibracion extends ConsumerWidget {
  const _LineaVibracion();

  static const List<String> _momentos = ['Inicio', 'Quedan 3 s', 'Final'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final paleta = context.paleta;
    final entreno = ref.watch(entrenoProvider);
    final cronometro = entreno.cronometro;
    if (cronometro == null) return const SizedBox.shrink();

    final transcurrido = cronometro.transcurridoS(entreno.ahora);
    final restante = cronometro.restanteS(entreno.ahora);

    final activo = switch (true) {
      _ when restante == 0 => 2,
      _ when restante <= segundosAvisoPrevio => 1,
      _ when transcurrido <= 1 => 0,
      _ => -1,
    };

    return Semantics(
      label: 'Avisos por vibración en esta fase: al empezar, a falta de tres '
          'segundos y al terminar.',
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(Icons.vibration, size: 16, color: paleta.textoSuave),
          const SizedBox(width: Espacio.s),
          for (var i = 0; i < _momentos.length; i++) ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: Espacio.xs),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == activo ? paleta.acentoSuave : Colors.transparent,
                  borderRadius: BorderRadius.circular(radioPildora),
                  border: Border.all(
                    color: i == activo ? paleta.acento : paleta.borde,
                  ),
                ),
                child: Text(
                  _momentos[i],
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: i == activo ? paleta.acento : paleta.textoSuave,
                  ),
                ),
              ),
            ),
            if (i < _momentos.length - 1) const SizedBox(width: Espacio.xs),
          ],
        ],
      ),
    );
  }
}
