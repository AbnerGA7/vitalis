/// Tarjeta de IMC en vivo con su banda. RF-03 · sección 4.1 · AC-03, AC-07.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nocturne_tema.dart';
import '../../core/nocturne_tokens.dart';
import '../../dominio/logica/imc.dart';
import '../../estado/notificador_app.dart';
import 'componentes.dart';

class TarjetaImc extends ConsumerWidget {
  const TarjetaImc({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final paleta = context.paleta;
    final estado = ref.watch(estadoAppProvider);
    final imc = estado.imc;
    final banda = estado.bandaImc;

    if (imc == null || banda == null) {
      return const TarjetaVitalis(
        resumenAccesible: 'Aún no se puede calcular el índice de masa corporal.',
        child: Text('Ajusta tu peso y tu altura para ver tu IMC.'),
      );
    }

    final valor = formatearImc(imc);
    return TarjetaVitalis(
      // El cambio se anuncia al recalcularse en vivo (AC-07).
      child: Semantics(
        liveRegion: true,
        container: true,
        label: 'Índice de masa corporal $valor, ${banda.etiqueta}. '
            'Es una orientación, no un diagnóstico.',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Índice de masa corporal', style: tema.textTheme.labelMedium),
            const SizedBox(height: Espacio.s),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(valor, style: tema.textTheme.displaySmall),
                const SizedBox(width: Espacio.m),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Espacio.m,
                      vertical: Espacio.xs,
                    ),
                    decoration: BoxDecoration(
                      color: paleta.acentoSuave,
                      borderRadius: BorderRadius.circular(radioPildora),
                      border: Border.all(color: paleta.acento),
                    ),
                    child: Text(
                      banda.etiqueta,
                      style: tema.textTheme.labelMedium?.copyWith(
                        color: paleta.acento,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Espacio.m),
            const _Rampa(),
            const SizedBox(height: Espacio.m),
            Text(
              'Sale de tu peso y tu altura. Es orientativo: Vitalis no da '
              'consejo médico ni diagnostica nada.',
              style: tema.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Rampa decorativa de bandas. La cifra de arriba es la fuente (AC-06).
class _Rampa extends ConsumerWidget {
  const _Rampa();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paleta = context.paleta;
    final banda = ref.watch(estadoAppProvider).bandaImc;
    return ExcludeSemantics(
      child: Row(
        children: [
          for (final valor in BandaImc.values) ...[
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: valor == banda ? paleta.acento : paleta.superficieAlta,
                  borderRadius: BorderRadius.circular(radioPildora),
                ),
              ),
            ),
            if (valor != BandaImc.values.last) const SizedBox(width: Espacio.xs),
          ],
        ],
      ),
    );
  }
}
