/// Hidratación: meta del día y registro rápido. RF-30, RF-31 · AC-02, AC-07.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nocturne_tema.dart';
import '../../core/nocturne_tokens.dart';
import '../../dominio/logica/hidratacion.dart';
import '../../estado/notificador_app.dart';
import '../widgets/componentes.dart';
import '../widgets/indicadores.dart';

class BloqueHidratacion extends ConsumerWidget {
  const BloqueHidratacion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final paleta = context.paleta;
    final estado = ref.watch(estadoAppProvider);
    final notificador = ref.read(estadoAppProvider.notifier);
    final enElTope = estado.aguaMl >= topeDiarioMl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TituloSeccion(
          'Hidratación',
          detalle: 'Meta del día: 2,5 litros. Se reinicia cada mañana.',
        ),
        const SizedBox(height: Espacio.m),
        TarjetaVitalis(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                liveRegion: true,
                container: true,
                // La cifra y la frase son la fuente; el anillo es decorativo
                // (AC-06).
                label: 'Llevas ${estado.aguaMl} mililitros de '
                    '$metaDiariaMl. ${estado.fraseAgua}',
                excludeSemantics: true,
                child: Row(
                  children: [
                    AnilloProgreso(
                      progreso: estado.progresoDeAgua,
                      diametro: 84,
                      child: Text(
                        '${(estado.progresoDeAgua * 100).round()}%',
                        style: tema.textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(width: Espacio.l),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${estado.aguaMl}',
                                style: tema.textTheme.headlineSmall?.copyWith(
                                  color: paleta.acento,
                                ),
                              ),
                              const SizedBox(width: Espacio.xs),
                              Text(
                                'de $metaDiariaMl ml',
                                style: tema.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: Espacio.s),
                          Text(
                            estado.fraseAgua,
                            style: tema.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Espacio.l),
              Wrap(
                spacing: Espacio.s,
                runSpacing: Espacio.s,
                children: [
                  PildoraAccion(
                    texto: '+250 ml',
                    nombreAccesible: 'Añadir 250 mililitros de agua',
                    onPressed: enElTope
                        ? null
                        : () => notificador.registrarAgua(vasoMl),
                  ),
                  PildoraAccion(
                    texto: '+500 ml',
                    nombreAccesible: 'Añadir 500 mililitros de agua',
                    onPressed: enElTope
                        ? null
                        : () => notificador.registrarAgua(vasoMl * 2),
                  ),
                ],
              ),
              if (enElTope) ...[
                const SizedBox(height: Espacio.m),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    'Has llegado al tope de registro del día '
                    '($topeDiarioMl ml). Mañana se reinicia.',
                    style: tema.textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
