/// Paso 3 del onboarding: confirmación de adaptaciones. Sección 3 · RF-05.
///
/// El prototipo dejaba este paso pendiente de diseño; aquí se implementa la
/// propuesta de la sección 3: repasar qué va a cambiar antes de entrar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nocturne_tokens.dart';
import '../../dominio/modelos/enums.dart';
import '../../estado/notificador_app.dart';
import '../widgets/componentes.dart';
import '../widgets/formato.dart';

class PasoResumen extends ConsumerWidget {
  const PasoResumen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final estado = ref.watch(estadoAppProvider);
    final necesidades = estado.preferencias.necesidades;
    final unidades = estado.preferencias.unidades;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text('Así queda tu Vitalis', style: tema.textTheme.headlineMedium),
        ),
        const SizedBox(height: Espacio.s),
        Text(
          'Repásalo antes de empezar. Todo esto se cambia después desde '
          'Perfil, sin repetir estos pasos.',
          style: tema.textTheme.bodyMedium,
        ),
        const SizedBox(height: Espacio.xl),

        TarjetaVitalis(
          resumenAccesible: 'Tus datos: '
              '${pesoHablado(estado.perfil.pesoKg, unidades)}, '
              '${alturaHablada(estado.perfil.alturaCm, unidades)}, '
              'objetivo ${estado.perfil.objetivo.etiqueta}, '
              '${estado.proteinaObjetivo} gramos de proteína al día.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Fila('Peso', textoPeso(estado.perfil.pesoKg, unidades)),
              _Fila('Altura', textoAltura(estado.perfil.alturaCm, unidades)),
              _Fila('Objetivo', estado.perfil.objetivo.etiqueta),
              _Fila('Proteína al día', '${estado.proteinaObjetivo} g'),
            ],
          ),
        ),
        const SizedBox(height: Espacio.l),

        TarjetaVitalis(
          resumenAccesible: necesidades.isEmpty
              ? 'No has marcado ninguna adaptación. Vitalis usará la '
                  'presentación estándar y podrás activar adaptaciones cuando '
                  'quieras desde Perfil.'
              : 'Adaptaciones activas: '
                  '${necesidades.map((n) => n.etiqueta).join('. ')}.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tus adaptaciones', style: tema.textTheme.titleMedium),
              const SizedBox(height: Espacio.m),
              if (necesidades.isEmpty)
                Text(
                  'No has marcado ninguna. Vitalis usará la presentación '
                  'estándar y podrás activarlas cuando quieras desde Perfil.',
                  style: tema.textTheme.bodyMedium,
                )
              else
                for (final necesidad in necesidades) ...[
                  _Adaptacion(necesidad),
                  if (necesidad != necesidades.last)
                    const SizedBox(height: Espacio.m),
                ],
            ],
          ),
        ),
        const SizedBox(height: Espacio.l),
        Text(
          'Las adaptaciones se acumulan: si marcas dos, verás las señales de '
          'las dos a la vez.',
          style: tema.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Espacio.m),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: tema.textTheme.bodyMedium),
          Text(valor, style: tema.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _Adaptacion extends StatelessWidget {
  const _Adaptacion(this.necesidad);

  final Necesidad necesidad;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ExcludeSemantics(child: Icon(Icons.check, size: 18)),
        const SizedBox(width: Espacio.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(necesidad.etiqueta, style: tema.textTheme.titleSmall),
              const SizedBox(height: Espacio.xs),
              Text(necesidad.descripcion, style: tema.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
