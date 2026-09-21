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

          const TituloSeccion(
            'Gustos',
            detalle: 'Texto libre, separado por comas. Sesga qué platos '
                'salen, nunca cuánta proteína necesitas.',
          ),
          const SizedBox(height: Espacio.m),
          const _PreferenciasComida(),
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

/// Campos de texto libre para gustos/exclusiones de comida (sección 4.3).
/// Guarda al perder el foco, no en cada tecla, para no escribir a disco de
/// más mientras la persona sigue escribiendo.
class _PreferenciasComida extends ConsumerStatefulWidget {
  const _PreferenciasComida();

  @override
  ConsumerState<_PreferenciasComida> createState() =>
      _PreferenciasComidaState();
}

class _PreferenciasComidaState extends ConsumerState<_PreferenciasComida> {
  late final TextEditingController _favoritas;
  late final TextEditingController _evitar;
  final _focoFavoritas = FocusNode();
  final _focoEvitar = FocusNode();

  @override
  void initState() {
    super.initState();
    final perfil = ref.read(estadoAppProvider).perfil;
    _favoritas = TextEditingController(text: perfil.comidasFavoritas);
    _evitar = TextEditingController(text: perfil.ingredientesEvitar);
    _focoFavoritas.addListener(_alPerderFocoFavoritas);
    _focoEvitar.addListener(_alPerderFocoEvitar);
  }

  void _alPerderFocoFavoritas() {
    if (!_focoFavoritas.hasFocus) {
      ref.read(estadoAppProvider.notifier).cambiarComidasFavoritas(_favoritas.text);
    }
  }

  void _alPerderFocoEvitar() {
    if (!_focoEvitar.hasFocus) {
      ref.read(estadoAppProvider.notifier).cambiarIngredientesEvitar(_evitar.text);
    }
  }

  @override
  void dispose() {
    _favoritas.dispose();
    _evitar.dispose();
    _focoFavoritas.dispose();
    _focoEvitar.dispose();
    super.dispose();
  }

  /// Si el perfil cambia por fuera de este campo (p. ej. «Borrar mis datos»
  /// en Perfil), sincroniza el texto. La pantalla de Dieta no se destruye al
  /// cambiar de pestaña (el shell usa `IndexedStack`), así que sin esto el
  /// campo se quedaba con el texto de antes de borrar. Solo se toca si el
  /// campo no tiene el foco, para no pisar lo que la persona está tecleando.
  void _sincronizarSiHaceFalta(
    TextEditingController controlador,
    FocusNode foco,
    String valorReal,
  ) {
    if (!foco.hasFocus && controlador.text != valorReal) {
      controlador.text = valorReal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = ref.watch(
      estadoAppProvider.select((estado) => estado.perfil),
    );
    _sincronizarSiHaceFalta(_favoritas, _focoFavoritas, perfil.comidasFavoritas);
    _sincronizarSiHaceFalta(_evitar, _focoEvitar, perfil.ingredientesEvitar);

    return TarjetaVitalis(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _favoritas,
            focusNode: _focoFavoritas,
            decoration: const InputDecoration(
              labelText: 'Te gusta',
              hintText: 'Ej: pollo, palta, quinua',
            ),
          ),
          const SizedBox(height: Espacio.m),
          TextField(
            controller: _evitar,
            focusNode: _focoEvitar,
            decoration: const InputDecoration(
              labelText: 'No te gusta / evitar',
              hintText: 'Ej: tomate, cebolla',
            ),
          ),
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
