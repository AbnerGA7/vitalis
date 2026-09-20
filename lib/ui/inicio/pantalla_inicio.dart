/// Inicio: el asistente de IA local. Sección 3 · RF-10…RF-16.
///
/// La IA es la puerta, no el único camino: Dieta, Entreno y Perfil siguen
/// accesibles desde la barra inferior.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nocturne_tema.dart';
import '../../core/nocturne_tokens.dart';
import '../../dominio/logica/clasificador_intenciones.dart';
import '../../dominio/modelos/mensaje.dart';
import '../../estado/estado_conversacion.dart';
import '../widgets/componentes.dart';
import '../widgets/orbe.dart';
import 'barra_entrada.dart';
import 'tarjeta_respuesta.dart';

class PantallaInicio extends ConsumerWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversacion = ref.watch(conversacionProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const _Cabecera(),
          Expanded(
            child: conversacion.vacia
                ? const _Vacio()
                : _Conversacion(mensajes: conversacion.mensajes),
          ),
          if (conversacion.fase == FaseAsistente.pensando)
            _Pensando(paso: conversacion.pasoPensando),
          const BarraEntrada(),
        ],
      ),
    );
  }
}

class _Cabecera extends ConsumerWidget {
  const _Cabecera();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final paleta = context.paleta;
    final fase = ref.watch(conversacionProvider.select((e) => e.fase));

    final estadoTexto = switch (fase) {
      FaseAsistente.reposo => 'Listo cuando quieras',
      FaseAsistente.escuchando => 'Escuchando',
      FaseAsistente.pensando => 'Pensando',
      FaseAsistente.respondido => 'Listo cuando quieras',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Espacio.l,
        Espacio.l,
        Espacio.l,
        Espacio.m,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text('Vitalis', style: tema.textTheme.headlineMedium),
                ),
                const SizedBox(height: Espacio.xs),
                Semantics(
                  liveRegion: true,
                  child: Text(estadoTexto, style: tema.textTheme.bodySmall),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Espacio.m,
              vertical: Espacio.xs,
            ),
            decoration: BoxDecoration(
              color: paleta.acentoSuave,
              borderRadius: BorderRadius.circular(radioPildora),
              border: Border.all(color: paleta.acento),
            ),
            child: Semantics(
              label: 'La inteligencia artificial funciona dentro de este '
                  'teléfono, sin conexión',
              excludeSemantics: true,
              child: Text(
                'IA local',
                style: tema.textTheme.labelMedium?.copyWith(
                  color: paleta.acento,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Conversación vacía: invitación más tres sugerencias (RF-14).
class _Vacio extends ConsumerWidget {
  const _Vacio();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final fase = ref.watch(conversacionProvider.select((e) => e.fase));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: Espacio.l),
      child: Column(
        children: [
          const SizedBox(height: Espacio.xl),
          Orbe(
            diametro: 132,
            estado: switch (fase) {
              FaseAsistente.escuchando => EstadoOrbe.escuchando,
              FaseAsistente.pensando => EstadoOrbe.hablando,
              _ => EstadoOrbe.reposo,
            },
          ),
          const SizedBox(height: Espacio.xl),
          Text(
            'Pídeme tu plan, el agua o el entreno',
            style: tema.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Espacio.m),
          Text(
            'Puedes escribirlo o dictarlo. Lo que digas no sale de este '
            'teléfono.',
            style: tema.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Espacio.xl),
          for (final sugerencia in sugerenciasInicio) ...[
            BotonVitalis(
              texto: sugerencia,
              ocuparAncho: true,
              nombreAccesible: 'Sugerencia: $sugerencia',
              onPressed: () =>
                  ref.read(conversacionProvider.notifier).enviar(sugerencia),
            ),
            const SizedBox(height: Espacio.s),
          ],
        ],
      ),
    );
  }
}

class _Conversacion extends StatelessWidget {
  const _Conversacion({required this.mensajes});

  final List<Mensaje> mensajes;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: Espacio.l),
      itemCount: mensajes.length,
      separatorBuilder: (_, __) => const SizedBox(height: Espacio.m),
      itemBuilder: (context, indice) => BurbujaMensaje(mensaje: mensajes[indice]),
    );
  }
}

/// Estado «pensando/generando» con texto por pasos (RF-15).
class _Pensando extends StatelessWidget {
  const _Pensando({required this.paso});

  final String paso;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Espacio.l,
        Espacio.m,
        Espacio.l,
        0,
      ),
      child: Semantics(
        liveRegion: true,
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: Espacio.m),
            Expanded(child: Text(paso, style: tema.textTheme.bodySmall)),
          ],
        ),
      ),
    );
  }
}
