/// Dieta: proteína del día, plan de cuatro comidas e hidratación.
/// Sección 3 · RF-20…RF-25, RF-30, RF-31.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nocturne_tema.dart';
import '../../core/nocturne_tokens.dart';
import '../../dominio/modelos/enums.dart';
import '../../estado/notificador_app.dart';
import '../widgets/componentes.dart';
import '../widgets/controles.dart';
import 'bloque_hidratacion.dart';
import 'tarjeta_plan.dart';

class PantallaDieta extends ConsumerWidget {
  const PantallaDieta({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(estadoAppProvider);
    final notificador = ref.read(estadoAppProvider.notifier);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(Espacio.l),
        children: [
          const TituloSeccion(
            'Dieta',
            detalle: 'Tu proteína del día y un plan de cuatro comidas '
                'generado aquí mismo, en el teléfono.',
          ),
          const SizedBox(height: Espacio.xl),
          const _TarjetaProteina(),
          const SizedBox(height: Espacio.xl),

          const TituloSeccion(
            'Tasa de proteína',
            detalle: 'Vitalis la propone según tu objetivo, pero la decides tú.',
          ),
          const SizedBox(height: Espacio.m),
          ControlSegmentado<TasaProteina>(
            etiquetaGrupo: 'Gramos de proteína por kilo de peso',
            seleccionado: estado.perfil.tasaProteina,
            onElegir: notificador.cambiarTasa,
            opciones: [
              for (final tasa in TasaProteina.values)
                OpcionSegmento(
                  valor: tasa,
                  etiqueta: '${tasa.etiqueta} '
                      '${tasa.gPorKg.toStringAsFixed(1).replaceAll('.', ',')}',
                  nombreAccesible: '${tasa.etiqueta}: '
                      '${tasa.gPorKg.toStringAsFixed(1).replaceAll('.', ',')} '
                      'gramos por kilo',
                ),
            ],
          ),
          const SizedBox(height: Espacio.xl),

          const TituloSeccion(
            'Preferencia',
            detalle: 'Cambia los platos, nunca la proteína que necesitas.',
          ),
          const SizedBox(height: Espacio.m),
          ControlSegmentado<PreferenciaDieta>(
            etiquetaGrupo: 'Preferencia dietética',
            seleccionado: estado.perfil.preferenciaDieta,
            onElegir: notificador.cambiarPreferenciaDieta,
            opciones: [
              for (final preferencia in PreferenciaDieta.values)
                OpcionSegmento(
                  valor: preferencia,
                  etiqueta: preferencia.etiqueta,
                  nombreAccesible: 'Dieta ${preferencia.etiqueta}',
                ),
            ],
          ),
          const SizedBox(height: Espacio.xl),

          const TarjetaPlan(),
          const SizedBox(height: Espacio.xl),

          const BloqueHidratacion(),
          const SizedBox(height: Espacio.xxl),
        ],
      ),
    );
  }
}

/// Proteína objetivo y su fórmula (RF-20, RF-51).
class _TarjetaProteina extends ConsumerWidget {
  const _TarjetaProteina();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final paleta = context.paleta;
    final estado = ref.watch(estadoAppProvider);

    return TarjetaVitalis(
      child: Semantics(
        liveRegion: true,
        container: true,
        label: 'Proteína de hoy: ${estado.proteinaObjetivo} gramos. '
            'Sale de ${estado.formula.replaceAll('×', 'por')}.',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Proteína de hoy', style: tema.textTheme.labelMedium),
            const SizedBox(height: Espacio.s),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${estado.proteinaObjetivo}',
                  style: tema.textTheme.displaySmall?.copyWith(
                    color: paleta.acento,
                  ),
                ),
                const SizedBox(width: Espacio.xs),
                Text('g', style: tema.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: Espacio.s),
            Text(estado.formula, style: tema.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
