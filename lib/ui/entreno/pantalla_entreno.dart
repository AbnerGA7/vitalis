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
import '../widgets/indicadores.dart';
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
          const SizedBox(height: Espacio.m),
          const _RutinaPorIA(),
        ],
      ),
    );
  }
}

/// Botón para pedirle a la IA local otra rutina, y el indicador mientras la
/// genera. La rutina en sí (no solo el texto) la decide el modelo cuando hay
/// uno cargado; sin modelo, Entreno sigue con el catálogo fijo de siempre.
class _RutinaPorIA extends ConsumerWidget {
  const _RutinaPorIA();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(estadoAppProvider);
    final notificador = ref.read(estadoAppProvider.notifier);

    final String clave;
    final Widget contenido;
    if (estado.generandoRutina) {
      clave = 'generando';
      contenido = _GenerandoRutina(actual: estado.pasoGeneracionRutina);
    } else {
      final hayRutinaIA = estado.rutinaIA != null;
      clave = hayRutinaIA ? 'regenerar' : 'generar';
      contenido = BotonVitalis(
        texto: hayRutinaIA ? 'Regenerar con IA' : 'Generar con IA',
        nombreAccesible: hayRutinaIA
            ? 'Pedirle a la IA otra rutina distinta'
            : 'Pedirle a la IA una rutina de ejercicios para hoy',
        ocuparAncho: true,
        onPressed: () => notificador.generarRutinaIA(regenerar: hayRutinaIA),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: movimientoReducido(context)
              ? Duration.zero
              : const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: KeyedSubtree(key: ValueKey(clave), child: contenido),
        ),
        if (estado.rutinaIAError != null) ...[
          const SizedBox(height: Espacio.s),
          _AvisoRutinaIA(mensaje: estado.rutinaIAError!),
        ],
      ],
    );
  }
}

/// Aviso cuando falla generar la rutina con IA (RF-15). Sin esto, la
/// pantalla se queda exactamente igual que antes de pulsar el botón —ya
/// mostraba una rutina del catálogo por defecto— y parece que no ha pasado
/// nada, a diferencia del plan de comidas, que siempre transiciona a un
/// plan visible aunque sea el de respaldo.
class _AvisoRutinaIA extends StatelessWidget {
  const _AvisoRutinaIA({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Text(
        mensaje,
        style: tema.textTheme.bodySmall?.copyWith(color: const Color(0xFFE2787C)),
      ),
    );
  }
}

/// Barra de progreso con los pasos de generación (RF-15), mismo patrón que
/// el plan de comidas en Dieta.
class _GenerandoRutina extends StatelessWidget {
  const _GenerandoRutina({required this.actual});

  final int actual;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final pasos = pasosDeGeneracionRutina;
    final progreso = pasos.isEmpty ? 0.0 : (actual + 1) / pasos.length;
    final texto = actual < pasos.length ? pasos[actual] : 'Terminando';

    return TarjetaVitalis(
      child: Semantics(
        liveRegion: true,
        label: 'Generando rutina con IA. $texto.',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Generando con IA', style: tema.textTheme.titleSmall),
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
