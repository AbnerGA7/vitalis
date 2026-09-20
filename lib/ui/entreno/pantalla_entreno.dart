/// Entreno: rutina del día, índice de rutinas y resumen semanal.
/// Sección 3 · RF-40, RF-41, RF-42.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nocturne_tema.dart';
import '../../core/nocturne_tokens.dart';
import '../../dominio/catalogo/rutinas.dart';
import '../../dominio/modelos/rutina.dart';
import '../../estado/estado_entreno.dart';
import '../../estado/notificador_app.dart';
import '../../estado/proveedores.dart';
import '../widgets/componentes.dart';
import 'resumen_semanal.dart';

class PantallaEntreno extends ConsumerWidget {
  const PantallaEntreno({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rutinaHoy = ref.watch(rutinaDelDiaProvider);
    final otras =
        todasLasRutinas.where((rutina) => rutina.id != rutinaHoy.id).toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(Espacio.l),
        children: [
          const TituloSeccion(
            'Entreno',
            detalle: 'Rutinas para hacer en casa, pensadas para adaptarse a ti.',
          ),
          const SizedBox(height: Espacio.xl),
          _RutinaDelDia(rutina: rutinaHoy),
          const SizedBox(height: Espacio.xl),
          const ResumenSemanal(),
          const SizedBox(height: Espacio.xl),
          const TituloSeccion(
            'Otras rutinas',
            detalle: 'Cada una explica para qué sirve. Ninguna se te oculta '
                'por las adaptaciones que tengas activas.',
          ),
          const SizedBox(height: Espacio.m),
          for (final rutina in otras) ...[
            _FichaRutina(rutina: rutina),
            const SizedBox(height: Espacio.m),
          ],
          const SizedBox(height: Espacio.xxl),
        ],
      ),
    );
  }
}

/// Rutina recomendada del día con etiquetas y nota de adaptación (RF-40).
class _RutinaDelDia extends ConsumerWidget {
  const _RutinaDelDia({required this.rutina});

  final Rutina rutina;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final preferencias =
        ref.watch(estadoAppProvider.select((estado) => estado.preferencias));
    final nota = notaAdaptacionPara(rutina, preferencias);

    return TarjetaVitalis(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hoy te propongo', style: tema.textTheme.labelMedium),
          const SizedBox(height: Espacio.s),
          Semantics(
            label: rutina.textoAccesible,
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${rutina.nombre} · ${rutina.duracionMin} min',
                  style: tema.textTheme.headlineSmall,
                ),
                const SizedBox(height: Espacio.m),
                _Etiquetas(rutina: rutina),
                const SizedBox(height: Espacio.m),
                Text(rutina.porque, style: tema.textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: Espacio.l),
          TarjetaVitalis(
            color: context.paleta.superficieAlta,
            padding: const EdgeInsets.all(Espacio.m),
            resumenAccesible: 'Cómo se adapta a ti: $nota',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cómo se adapta a ti', style: tema.textTheme.titleSmall),
                const SizedBox(height: Espacio.s),
                Text(nota, style: tema.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: Espacio.l),
          BotonVitalis(
            texto: 'Empezar entrenamiento',
            nombreAccesible: 'Empezar el entrenamiento ${rutina.nombre}, '
                '${rutina.duracionMin} minutos',
            ocuparAncho: true,
            onPressed: () => ref.read(entrenoProvider.notifier).empezar(rutina),
          ),
        ],
      ),
    );
  }
}

/// Etiquetas de duración, ejercicios, material e impacto (RF-40).
class _Etiquetas extends StatelessWidget {
  const _Etiquetas({required this.rutina});

  final Rutina rutina;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final paleta = context.paleta;
    final etiquetas = [
      '${rutina.duracionMin} min',
      '${rutina.numeroEjercicios} ejercicios',
      rutina.material,
      'Impacto ${rutina.impacto}',
    ];

    return ExcludeSemantics(
      child: Wrap(
        spacing: Espacio.s,
        runSpacing: Espacio.s,
        children: [
          for (final etiqueta in etiquetas)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Espacio.m,
                vertical: Espacio.xs,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radioPildora),
                border: Border.all(color: paleta.borde),
              ),
              child: Text(etiqueta, style: tema.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

/// Ficha del índice de rutinas, cada una con su «por qué» (RF-41).
class _FichaRutina extends ConsumerWidget {
  const _FichaRutina({required this.rutina});

  final Rutina rutina;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    return TarjetaVitalis(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: rutina.textoAccesible,
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${rutina.nombre} · ${rutina.duracionMin} min',
                  style: tema.textTheme.titleMedium,
                ),
                const SizedBox(height: Espacio.s),
                _Etiquetas(rutina: rutina),
                const SizedBox(height: Espacio.m),
                Text(rutina.porque, style: tema.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: Espacio.m),
          BotonVitalis(
            texto: 'Empezar',
            nombreAccesible: 'Empezar el entrenamiento ${rutina.nombre}, '
                '${rutina.duracionMin} minutos',
            onPressed: () => ref.read(entrenoProvider.notifier).empezar(rutina),
          ),
        ],
      ),
    );
  }
}
