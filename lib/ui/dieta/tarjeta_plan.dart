/// Plan de cuatro comidas con su porqué. RF-22, RF-23, RF-24 · AC-03, AC-07.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nocturne_tema.dart';
import '../../core/nocturne_tokens.dart';
import '../../dominio/catalogo/platos.dart';
import '../../dominio/modelos/plan_comidas.dart';
import '../../estado/notificador_app.dart';
import '../../estado/proveedores.dart';
import '../widgets/componentes.dart';
import '../widgets/indicadores.dart';

class TarjetaPlan extends ConsumerWidget {
  const TarjetaPlan({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(estadoAppProvider);
    final notificador = ref.read(estadoAppProvider.notifier);

    final String clave;
    final Widget contenido;
    if (estado.generandoPlan) {
      clave = 'generando';
      contenido = _Generando(
        pasos: ref.read(motorIaProvider).pasosDeGeneracion,
        actual: estado.pasoGeneracion,
      );
    } else {
      final plan = estado.plan;
      if (plan == null || !estado.planVigente) {
        clave = 'sin-plan';
        contenido = _SinPlan(
          desactualizado: plan != null,
          onGenerar: notificador.generarPlan,
        );
      } else {
        clave = 'con-plan';
        contenido = _ConPlan(plan: plan);
      }
    }

    // Cruce suave entre «generando» / «sin plan» / «con plan» en vez de un
    // salto seco; respeta «movimiento reducido» igual que el resto de
    // animaciones decorativas de la app (RNF-05).
    return AnimatedSwitcher(
      duration: movimientoReducido(context)
          ? Duration.zero
          : const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(key: ValueKey(clave), child: contenido),
    );
  }
}

class _SinPlan extends StatelessWidget {
  const _SinPlan({required this.desactualizado, required this.onGenerar});

  final bool desactualizado;
  final VoidCallback onGenerar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return TarjetaVitalis(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            desactualizado
                ? 'Tu plan se ha quedado viejo'
                : 'Todavía no hay plan',
            style: tema.textTheme.titleMedium,
          ),
          const SizedBox(height: Espacio.s),
          Text(
            desactualizado
                ? 'Has cambiado algo que afecta al reparto de proteína. '
                    'Genera uno nuevo para que cuadre con tus datos de ahora.'
                : 'Vitalis reparte tu proteína en cuatro comidas. Todo se '
                    'calcula aquí, sin enviar nada a ningún sitio.',
            style: tema.textTheme.bodyMedium,
          ),
          const SizedBox(height: Espacio.l),
          BotonVitalis(
            texto: desactualizado ? 'Generar plan nuevo' : 'Generar mi plan',
            nombreAccesible: 'Generar el plan de comidas de hoy',
            ocuparAncho: true,
            onPressed: onGenerar,
          ),
        ],
      ),
    );
  }
}

/// Barra más texto con los pasos de generación (RF-15).
class _Generando extends StatelessWidget {
  const _Generando({required this.pasos, required this.actual});

  final List<String> pasos;
  final int actual;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final progreso = pasos.isEmpty ? 0.0 : (actual + 1) / pasos.length;
    final texto = actual < pasos.length ? pasos[actual] : 'Terminando';

    return TarjetaVitalis(
      child: Semantics(
        liveRegion: true,
        label: 'Generando tu plan. $texto.',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Generando tu plan', style: tema.textTheme.titleMedium),
            const SizedBox(height: Espacio.m),
            ClipRRect(
              borderRadius: BorderRadius.circular(radioPildora),
              child: LinearProgressIndicator(value: progreso, minHeight: 6),
            ),
            const SizedBox(height: Espacio.m),
            Text(texto, style: tema.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ConPlan extends ConsumerWidget {
  const _ConPlan({required this.plan});

  final PlanComidas plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final estado = ref.watch(estadoAppProvider);
    final notificador = ref.read(estadoAppProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TarjetaVitalis(
          resumenAccesible: 'Plan de hoy: ${plan.totalProteinaG} gramos de '
              'proteína y ${plan.totalKcal} kilocalorías en cuatro comidas.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tu plan de hoy', style: tema.textTheme.titleMedium),
                  if (estado.planUsadoHoy)
                    Text('En uso', style: tema.textTheme.labelMedium),
                ],
              ),
              const SizedBox(height: Espacio.l),
              for (var i = 0; i < plan.comidas.length; i++) ...[
                _FilaComida(comida: plan.comidas[i], numero: i + 1),
                if (i < plan.comidas.length - 1) ...[
                  const SizedBox(height: Espacio.m),
                  Divider(height: 1, color: context.paleta.borde),
                  const SizedBox(height: Espacio.m),
                ],
              ],
              const SizedBox(height: Espacio.l),
              Semantics(
                label: 'Totales del día: ${plan.totalProteinaG} gramos de '
                    'proteína y ${plan.totalKcal} kilocalorías.',
                excludeSemantics: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: tema.textTheme.titleSmall),
                    Text(
                      '${plan.totalProteinaG} g · ${plan.totalKcal} kcal',
                      style: tema.textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Espacio.m),
        _PorQue(porque: plan.porque),
        const SizedBox(height: Espacio.m),
        Wrap(
          spacing: Espacio.s,
          runSpacing: Espacio.s,
          children: [
            BotonVitalis(
              texto: 'Regenerar',
              nombreAccesible: 'Generar otro plan de comidas distinto',
              onPressed: () => notificador.generarPlan(regenerar: true),
            ),
            BotonVitalis(
              texto: estado.planUsadoHoy ? 'En uso hoy' : 'Usar en el día',
              nombreAccesible: estado.planUsadoHoy
                  ? 'Este plan ya está en uso hoy'
                  : 'Usar este plan en el día de hoy',
              onPressed:
                  estado.planUsadoHoy ? null : notificador.usarPlanEnElDia,
            ),
          ],
        ),
      ],
    );
  }
}

class _FilaComida extends StatelessWidget {
  const _FilaComida({required this.comida, required this.numero});

  final Comida comida;
  final int numero;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Semantics(
      label: comida.textoAccesible(numero),
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(comida.hora, style: tema.textTheme.labelMedium),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${nombresFranjas[numero - 1]} · ${comida.plato}',
                  style: tema.textTheme.bodyLarge,
                ),
                const SizedBox(height: Espacio.xs),
                Text(
                  comida.ingredientes.join(', '),
                  style: tema.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: Espacio.s),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${comida.proteinaG} g', style: tema.textTheme.titleSmall),
              Text('${comida.kcal} kcal', style: tema.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

/// «Por qué este plan» (RF-23): la app recomienda, no manda.
class _PorQue extends StatelessWidget {
  const _PorQue({required this.porque});

  final String porque;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return TarjetaVitalis(
      color: context.paleta.superficieAlta,
      resumenAccesible: 'Por qué este plan: $porque',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Por qué este plan', style: tema.textTheme.titleSmall),
          const SizedBox(height: Espacio.s),
          Text(porque, style: tema.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
