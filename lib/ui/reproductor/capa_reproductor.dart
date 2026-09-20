/// Reproductor a pantalla completa. Sección 3 · RF-43, RF-44, RF-45, RF-60,
/// RF-61, RF-62.
///
/// Es una capa, no una pestaña: mientras se entrena no hay navegación que
/// distraiga ni destino por error.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nocturne_tema.dart';
import '../../core/nocturne_tokens.dart';
import '../../dominio/logica/cronometro.dart';
import '../../dominio/modelos/enums.dart';
import '../../estado/estado_entreno.dart';
import '../../estado/notificador_app.dart';
import '../widgets/indicadores.dart';
import 'controles_reproductor.dart';
import 'senales_reproductor.dart';

class CapaReproductor extends ConsumerWidget {
  const CapaReproductor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entreno = ref.watch(entrenoProvider);
    final cronometro = entreno.cronometro;
    if (cronometro == null) return const SizedBox.shrink();

    final preferencias =
        ref.watch(estadoAppProvider.select((estado) => estado.preferencias));
    final paleta = context.paleta;

    // El destello verde del fin de descanso rompe a propósito la regla de
    // Nocturne de no inundar de color: es la única señal no sonora del
    // evento, así que prevalece (sección 6).
    final fondo = entreno.destellando ? verdeTrabajo : paleta.fondo;
    final sobreFondo = entreno.destellando ? tintaSobreVerde : paleta.texto;

    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: AnimatedContainer(
        duration: movimientoReducido(context)
            ? Duration.zero
            : const Duration(milliseconds: 220),
        color: fondo,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: sobreFondo),
          child: IconTheme.merge(
            data: IconThemeData(color: sobreFondo),
            child: SafeArea(
              child: Column(
                children: [
                  const CabeceraReproductor(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Espacio.l,
                      ),
                      child: _CuerpoFase(
                        cronometro: cronometro,
                        ahora: entreno.ahora,
                        tipografiaMayor: preferencias.tipografiaMayor,
                        anilloReducido: preferencias.tipografiaMayor,
                      ),
                    ),
                  ),
                  const SenalesReproductor(),
                  const ControlesReproductor(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CuerpoFase extends StatelessWidget {
  const _CuerpoFase({
    required this.cronometro,
    required this.ahora,
    required this.tipografiaMayor,
    required this.anilloReducido,
  });

  final EstadoCronometro cronometro;
  final DateTime ahora;

  /// Perfil de ceguera o baja visión: tipografía mayor, anillo reducido
  /// (RF-61).
  final bool tipografiaMayor;
  final bool anilloReducido;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final paso = cronometro.paso;
    final restante = cronometro.restanteS(ahora);
    final esTrabajo = paso.tipo == TipoPaso.trabajo;
    final nombreFase = esTrabajo ? 'Trabajo' : 'Descanso';

    final tamanoCuenta = tipografiaMayor ? 104.0 : 80.0;
    final diametroAnillo = anilloReducido ? 150.0 : 210.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Espacio.l),
        BarraPasos(
          total: cronometro.totalPasos,
          actual: cronometro.numeroPaso,
        ),
        const SizedBox(height: Espacio.xl),

        Text(
          nombreFase.toUpperCase(),
          style: tema.textTheme.labelMedium?.copyWith(
            color: esTrabajo ? verdeTrabajo : null,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: Espacio.s),
        Text(
          paso.nombre,
          style: tipografiaMayor
              ? tema.textTheme.displaySmall
              : tema.textTheme.headlineMedium,
        ),
        const SizedBox(height: Espacio.s),
        Text(paso.detalle, style: tema.textTheme.bodyLarge),
        const SizedBox(height: Espacio.xl),

        // La cifra es la fuente accesible; el anillo es decorativo (AC-06).
        Center(
          child: Semantics(
            liveRegion: true,
            label: '$nombreFase. ${paso.nombre}. '
                '$restante segundos restantes.',
            excludeSemantics: true,
            child: AnilloProgreso(
              progreso: 1 - cronometro.progresoFase(ahora),
              diametro: diametroAnillo,
              color: esTrabajo ? verdeTrabajo : null,
              child: Text(
                formatearCuentaAtras(restante),
                style: TextStyle(
                  fontSize: tamanoCuenta,
                  height: 1,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Espacio.xl),

        _EspacioAnimacion(indicacion: paso.indicacion),
        const SizedBox(height: Espacio.l),
      ],
    );
  }
}

/// Espacio reservado para el bucle de animación de técnica (RF-44).
///
/// El recurso aún no existe (ADR-06). Hasta entonces el hueco muestra la
/// indicación escrita, que es lo que sostiene la información.
class _EspacioAnimacion extends StatelessWidget {
  const _EspacioAnimacion({required this.indicacion});

  final String indicacion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final paleta = context.paleta;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Espacio.l),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radioTarjeta),
        border: Border.all(color: paleta.borde),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExcludeSemantics(
            child: Icon(Icons.play_circle_outline, size: 20),
          ),
          const SizedBox(width: Espacio.m),
          Expanded(
            child: Text(indicacion, style: tema.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
