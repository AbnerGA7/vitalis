/// Cabecera y controles del reproductor. RF-43 · AC-01, AC-02.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nocturne_tema.dart';
import '../../core/nocturne_tokens.dart';
import '../../estado/estado_entreno.dart';
import '../../estado/notificador_app.dart';

/// «n de N · nombre de rutina», perfil activo y Salir.
class CabeceraReproductor extends ConsumerWidget {
  const CabeceraReproductor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final cronometro =
        ref.watch(entrenoProvider.select((estado) => estado.cronometro));
    if (cronometro == null) return const SizedBox.shrink();

    final necesidades =
        ref.watch(estadoAppProvider.select((e) => e.preferencias.necesidades));
    final perfilActivo = necesidades.isEmpty
        ? 'Presentación estándar'
        : necesidades.map((n) => n.etiqueta).join(' + ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Espacio.l,
        Espacio.m,
        Espacio.s,
        Espacio.s,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Semantics(
              label: 'Paso ${cronometro.numeroPaso} de '
                  '${cronometro.totalPasos} de ${cronometro.rutina.nombre}. '
                  'Perfil activo: $perfilActivo.',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${cronometro.numeroPaso} de ${cronometro.totalPasos} · '
                    '${cronometro.rutina.nombre}',
                    style: tema.textTheme.titleSmall,
                  ),
                  const SizedBox(height: Espacio.xs),
                  Text(perfilActivo, style: tema.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Salir del entrenamiento',
            excludeSemantics: true,
            child: TextButton.icon(
              onPressed: () => ref.read(entrenoProvider.notifier).salir(),
              icon: const Icon(Icons.close),
              label: const Text('Salir'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Anterior, pausa/reanudar y siguiente. Todos de 64 dp para que no haga
/// falta puntería en mitad del ejercicio (AC-01).
class ControlesReproductor extends ConsumerWidget {
  const ControlesReproductor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entreno = ref.watch(entrenoProvider);
    final cronometro = entreno.cronometro;
    if (cronometro == null) return const SizedBox.shrink();

    final notificador = ref.read(entrenoProvider.notifier);
    final enPausa = cronometro.enPausa;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Espacio.l,
        Espacio.m,
        Espacio.l,
        Espacio.l,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BotonControl(
            icono: Icons.skip_previous,
            nombre: 'Paso anterior',
            onPulsar: notificador.anterior,
          ),
          _BotonControl(
            icono: enPausa ? Icons.play_arrow : Icons.pause,
            nombre: enPausa
                ? 'Reanudar el entrenamiento'
                : 'Pausar el entrenamiento',
            destacado: true,
            onPulsar: enPausa ? notificador.reanudar : notificador.pausar,
          ),
          _BotonControl(
            icono: Icons.skip_next,
            nombre: 'Paso siguiente',
            onPulsar: notificador.siguiente,
          ),
        ],
      ),
    );
  }
}

class _BotonControl extends StatelessWidget {
  const _BotonControl({
    required this.icono,
    required this.nombre,
    required this.onPulsar,
    this.destacado = false,
  });

  final IconData icono;
  final String nombre;
  final VoidCallback onPulsar;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Semantics(
      button: true,
      label: nombre,
      excludeSemantics: true,
      child: SizedBox(
        width: areaMicro,
        height: areaMicro,
        child: IconButton(
          onPressed: onPulsar,
          icon: Icon(icono, size: destacado ? 30 : 24),
          style: IconButton.styleFrom(
            shape: const CircleBorder(),
            side: BorderSide(
              color: paleta.acento,
              width: destacado ? 2 : 1,
            ),
            backgroundColor:
                destacado ? paleta.acentoSuave : Colors.transparent,
          ),
        ),
      ),
    );
  }
}
