/// Resumen semanal de sesiones. Sección 3 · RF-42.
///
/// Sale del historial de sesiones guardado en el dispositivo (sección 5).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nocturne_tema.dart';
import '../../core/nocturne_tokens.dart';
import '../../estado/estado_entreno.dart';
import '../../estado/notificador_app.dart';
import '../widgets/componentes.dart';

/// Sesiones por semana que Vitalis propone (supuesto, pendiente de validar).
const int sesionesPorSemana = 5;

const List<String> _inicialesDias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
const List<String> _nombresDias = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

class ResumenSemanal extends ConsumerWidget {
  const ResumenSemanal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final hoy = ref.watch(estadoAppProvider.select((estado) => estado.dia));
    final sesiones = ref.watch(sesionesProvider);

    return sesiones.when(
      loading: () => const TarjetaVitalis(
        resumenAccesible: 'Cargando tu resumen de la semana.',
        child: Text('Cargando tu semana…'),
      ),
      error: (_, __) => const TarjetaVitalis(
        resumenAccesible: 'No se ha podido leer el historial de sesiones.',
        child: Text('No he podido leer tu historial de sesiones.'),
      ),
      data: (lista) {
        final lunes = hoy.subtract(Duration(days: hoy.weekday - 1));
        final hechas = <int>{};
        for (final sesion in lista) {
          if (!sesion.completada) continue;
          final diferencia = sesion.fecha.difference(lunes).inDays;
          if (diferencia >= 0 && diferencia < 7) hechas.add(diferencia);
        }

        return TarjetaVitalis(
          resumenAccesible: _resumenHablado(hechas, hoy.weekday - 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tu semana', style: tema.textTheme.titleMedium),
              const SizedBox(height: Espacio.l),
              _Dias(hechas: hechas, indiceHoy: hoy.weekday - 1),
              const SizedBox(height: Espacio.l),
              Text(
                _resumenVisible(hechas, hoy.weekday - 1),
                style: tema.textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}

String _resumenVisible(Set<int> hechas, int indiceHoy) {
  final base = '${hechas.length} de $sesionesPorSemana sesiones hechas.';
  final pendiente = _primerDiaPendiente(hechas, indiceHoy);
  if (pendiente == null) return '$base Vas al día.';
  return '$base El ${_nombresDias[pendiente]} está pendiente.';
}

String _resumenHablado(Set<int> hechas, int indiceHoy) =>
    'Resumen de la semana. ${_resumenVisible(hechas, indiceHoy)}';

/// Primer día ya pasado (o de hoy) sin sesión completada.
int? _primerDiaPendiente(Set<int> hechas, int indiceHoy) {
  for (var dia = 0; dia <= indiceHoy; dia++) {
    if (!hechas.contains(dia)) return dia;
  }
  return null;
}

/// Fila L–D. Es decorativa: el texto de debajo es la fuente (AC-06).
class _Dias extends StatelessWidget {
  const _Dias({required this.hechas, required this.indiceHoy});

  final Set<int> hechas;
  final int indiceHoy;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final paleta = context.paleta;

    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var dia = 0; dia < 7; dia++)
            Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hechas.contains(dia)
                        ? paleta.acento
                        : paleta.superficieAlta,
                    border: dia == indiceHoy
                        ? Border.all(color: paleta.acento, width: 2)
                        : null,
                  ),
                  child: Text(
                    _inicialesDias[dia],
                    style: tema.textTheme.labelMedium?.copyWith(
                      color: hechas.contains(dia)
                          ? paleta.tintaSobreAcento
                          : paleta.textoSuave,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
