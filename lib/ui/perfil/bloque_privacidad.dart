/// Privacidad y exportación. RF-52 · sección 5 · RNF-01, RNF-10.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nocturne_tokens.dart';
import '../../estado/estado_conversacion.dart';
import '../../estado/notificador_app.dart';
import '../widgets/componentes.dart';

class BloquePrivacidad extends ConsumerWidget {
  const BloquePrivacidad({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TituloSeccion('Privacidad'),
        const SizedBox(height: Espacio.m),
        TarjetaVitalis(
          resumenAccesible: 'Privacidad: Vitalis no tiene cuenta, no se '
              'sincroniza con ningún servidor y no recoge estadísticas de uso. '
              'Todo se guarda en este teléfono y desaparece si desinstalas la '
              'aplicación.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vitalis no tiene cuenta, no se sincroniza con ningún servidor '
                'y no recoge estadísticas de uso. Tu peso, tus planes y tus '
                'entrenamientos se guardan solo en este teléfono.',
                style: tema.textTheme.bodyMedium,
              ),
              const SizedBox(height: Espacio.m),
              Text(
                'Si desinstalas la aplicación, todo desaparece con ella.',
                style: tema.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: Espacio.m),
        BotonVitalis(
          texto: 'Exportar mis datos',
          nombreAccesible: 'Exportar mis datos y copiarlos al portapapeles',
          ocuparAncho: true,
          onPressed: () => _exportar(context, ref),
        ),
        const SizedBox(height: Espacio.s),
        BotonVitalis(
          texto: 'Borrar mis datos',
          nombreAccesible: 'Borrar todos mis datos de este teléfono',
          ocuparAncho: true,
          onPressed: () => _confirmarBorrado(context, ref),
        ),
      ],
    );
  }

  /// Volcado legible en JSON (ADR-08). Se muestra y se copia: no sale de aquí
  /// salvo que la persona decida pegarlo en otro sitio.
  Future<void> _exportar(BuildContext context, WidgetRef ref) async {
    final volcado = await ref.read(estadoAppProvider.notifier).exportarDatos();
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tus datos'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              volcado,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: volcado));
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Copiar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarBorrado(BuildContext context, WidgetRef ref) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar todos tus datos?'),
        content: const Text(
          'Se borrarán tu perfil, tus preferencias, el plan de hoy, el agua '
          'registrada y el historial de entrenamientos. No se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;
    await ref.read(estadoAppProvider.notifier).borrarDatos();
    if (!ref.context.mounted) return;
    ref.read(conversacionProvider.notifier).vaciar();
  }
}
