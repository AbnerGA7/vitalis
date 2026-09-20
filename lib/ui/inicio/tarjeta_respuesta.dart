/// Burbujas de la conversación y tarjetas de respuesta. RF-13 · AC-03.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nocturne_tema.dart';
import '../../core/nocturne_tokens.dart';
import '../../dominio/logica/hidratacion.dart';
import '../../dominio/modelos/mensaje.dart';
import '../../estado/estado_conversacion.dart';
import '../../estado/estado_entreno.dart';
import '../../estado/notificador_app.dart';
import '../../estado/proveedores.dart';
import '../cascaron.dart';
import '../widgets/componentes.dart';

class BurbujaMensaje extends ConsumerWidget {
  const BurbujaMensaje({super.key, required this.mensaje});

  final Mensaje mensaje;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final paleta = context.paleta;

    if (mensaje.autor == Autor.persona) {
      return Align(
        alignment: Alignment.centerRight,
        child: Semantics(
          label: 'Tú: ${mensaje.texto}',
          excludeSemantics: true,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(
              horizontal: Espacio.l,
              vertical: Espacio.m,
            ),
            decoration: BoxDecoration(
              color: paleta.acentoSuave,
              borderRadius: BorderRadius.circular(radioTarjeta),
              border: Border.all(color: paleta.borde),
            ),
            child: Text(mensaje.texto, style: tema.textTheme.bodyMedium),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TarjetaVitalis(
          resumenAccesible: 'Vitalis: ${mensaje.texto}',
          child: Text(mensaje.texto, style: tema.textTheme.bodyMedium),
        ),
        const SizedBox(height: Espacio.s),
        switch (mensaje.tipo) {
          TipoMensaje.plan => _AccionesPlan(mensaje: mensaje),
          TipoMensaje.agua => const _AccionesAgua(),
          TipoMensaje.entreno => const _AccionesEntreno(),
          TipoMensaje.noEntendido => _Ejemplos(ejemplos: mensaje.ejemplos),
          TipoMensaje.texto => const SizedBox.shrink(),
        },
      ],
    );
  }
}

class _AccionesPlan extends ConsumerWidget {
  const _AccionesPlan({required this.mensaje});

  final Mensaje mensaje;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = mensaje.plan;
    if (plan == null) return const SizedBox.shrink();
    final tema = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TarjetaVitalis(
          resumenAccesible: 'Plan propuesto: '
              '${plan.totalProteinaG} gramos de proteína y '
              '${plan.totalKcal} kilocalorías en cuatro comidas.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < plan.comidas.length; i++) ...[
                Semantics(
                  label: plan.comidas[i].textoAccesible(i + 1),
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 52,
                        child: Text(
                          plan.comidas[i].hora,
                          style: tema.textTheme.labelMedium,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          plan.comidas[i].plato,
                          style: tema.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '${plan.comidas[i].proteinaG} g',
                        style: tema.textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
                if (i < plan.comidas.length - 1)
                  const SizedBox(height: Espacio.m),
              ],
            ],
          ),
        ),
        const SizedBox(height: Espacio.s),
        Wrap(
          spacing: Espacio.s,
          runSpacing: Espacio.s,
          children: [
            BotonVitalis(
              texto: 'Usar este plan',
              nombreAccesible: 'Usar este plan de comidas en el día de hoy',
              onPressed: () {
                ref.read(estadoAppProvider.notifier).adoptarPlan(plan);
                ref.read(pestanaProvider.notifier).state = 1;
              },
            ),
            BotonVitalis(
              texto: 'Otro',
              nombreAccesible: 'Pedir otro plan de comidas distinto',
              onPressed: () => ref
                  .read(conversacionProvider.notifier)
                  .enviar('Dame otro plan de comidas'),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccionesAgua extends ConsumerWidget {
  const _AccionesAgua();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificador = ref.read(estadoAppProvider.notifier);
    return Wrap(
      spacing: Espacio.s,
      runSpacing: Espacio.s,
      children: [
        PildoraAccion(
          texto: '+250 ml',
          nombreAccesible: 'Añadir 250 mililitros de agua',
          onPressed: () => notificador.registrarAgua(vasoMl),
        ),
        PildoraAccion(
          texto: '+500 ml',
          nombreAccesible: 'Añadir 500 mililitros de agua',
          onPressed: () => notificador.registrarAgua(vasoMl * 2),
        ),
      ],
    );
  }
}

class _AccionesEntreno extends ConsumerWidget {
  const _AccionesEntreno();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rutina = ref.watch(rutinaDelDiaProvider);
    return BotonVitalis(
      texto: 'Empezar entrenamiento',
      nombreAccesible: 'Empezar el entrenamiento ${rutina.nombre}',
      onPressed: () => ref.read(entrenoProvider.notifier).empezar(rutina),
    );
  }
}

/// Tres ejemplos cuando no se ha entendido. No inventa (RF-12).
class _Ejemplos extends ConsumerWidget {
  const _Ejemplos({required this.ejemplos});

  final List<String> ejemplos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final ejemplo in ejemplos) ...[
          BotonVitalis(
            texto: ejemplo,
            ocuparAncho: true,
            nombreAccesible: 'Pedir: $ejemplo',
            onPressed: () =>
                ref.read(conversacionProvider.notifier).enviar(ejemplo),
          ),
          const SizedBox(height: Espacio.s),
        ],
      ],
    );
  }
}
