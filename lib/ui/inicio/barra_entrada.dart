/// Entrada del asistente: campo de texto y micro. RF-10, RF-11 · AC-01, AC-08,
/// AC-11.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nocturne_tema.dart';
import '../../core/nocturne_tokens.dart';
import '../../estado/estado_conversacion.dart';

class BarraEntrada extends ConsumerStatefulWidget {
  const BarraEntrada({super.key});

  @override
  ConsumerState<BarraEntrada> createState() => _BarraEntradaState();
}

class _BarraEntradaState extends ConsumerState<BarraEntrada> {
  final TextEditingController _controlador = TextEditingController();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final conversacion = ref.watch(conversacionProvider);
    final notificador = ref.read(conversacionProvider.notifier);

    // El micro rellena el mismo campo y lo dictado queda editable antes de
    // enviarlo (RF-10). Se escucha el cambio en vez de reescribir el campo en
    // cada build: si no, cada pulsación devolvería el cursor al final y sería
    // imposible corregir por el medio de lo dictado.
    ref.listen(conversacionProvider.select((estado) => estado.borrador),
        (_, borrador) {
      if (_controlador.text == borrador) return;
      _controlador.value = TextEditingValue(
        text: borrador,
        selection: TextSelection.collapsed(offset: borrador.length),
      );
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(
        Espacio.l,
        Espacio.m,
        Espacio.l,
        Espacio.m,
      ),
      decoration: BoxDecoration(
        color: paleta.fondo,
        border: Border(top: BorderSide(color: paleta.borde)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (conversacion.escuchando) const _Escuchando(),
            if (conversacion.errorVoz != null) _ErrorVoz(conversacion.errorVoz!),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controlador,
                    onChanged: notificador.escribir,
                    onSubmitted: (_) => notificador.enviar(),
                    textInputAction: TextInputAction.send,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Escribe o dicta lo que necesitas',
                      labelText: 'Mensaje para Vitalis',
                    ),
                  ),
                ),
                const SizedBox(width: Espacio.s),
                if (conversacion.vozDisponible) const _BotonMicro(),
                const SizedBox(width: Espacio.s),
                _BotonEnviar(
                  activo: conversacion.borrador.trim().isNotEmpty,
                  onPulsar: notificador.enviar,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Micro de 64 dp (AC-01).
class _BotonMicro extends ConsumerWidget {
  const _BotonMicro();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paleta = context.paleta;
    final escuchando =
        ref.watch(conversacionProvider.select((e) => e.escuchando));

    return Semantics(
      button: true,
      label: escuchando ? 'Detener el dictado' : 'Dictar por voz',
      excludeSemantics: true,
      child: SizedBox(
        width: areaMicro,
        height: areaMicro,
        child: IconButton(
          onPressed: ref.read(conversacionProvider.notifier).iniciarDictado,
          icon: Icon(escuchando ? Icons.stop : Icons.mic_none),
          style: IconButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor:
                escuchando ? paleta.acentoSuave : Colors.transparent,
            side: BorderSide(color: paleta.acento, width: escuchando ? 2 : 1),
            foregroundColor: paleta.acento,
          ),
        ),
      ),
    );
  }
}

class _BotonEnviar extends StatelessWidget {
  const _BotonEnviar({required this.activo, required this.onPulsar});

  final bool activo;
  final VoidCallback onPulsar;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Semantics(
      button: true,
      enabled: activo,
      label: 'Enviar el mensaje a Vitalis',
      excludeSemantics: true,
      child: SizedBox(
        width: areaTactilMinima,
        height: areaTactilMinima,
        child: IconButton(
          onPressed: activo ? onPulsar : null,
          icon: const Icon(Icons.arrow_upward),
          style: IconButton.styleFrom(
            shape: const CircleBorder(),
            side: BorderSide(
              color: activo ? paleta.acento : paleta.borde,
            ),
            foregroundColor: activo ? paleta.acento : paleta.textoSuave,
          ),
        ),
      ),
    );
  }
}

/// Barras animadas más la transcripción en vivo.
///
/// Las barras son la gemela visual del pitido del dictado, y la transcripción
/// hace de subtítulo para quien no oye (AC-08, AC-12, RF-11).
class _Escuchando extends ConsumerWidget {
  const _Escuchando();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final paleta = context.paleta;
    final borrador = ref.watch(conversacionProvider.select((e) => e.borrador));

    return Padding(
      padding: const EdgeInsets.only(bottom: Espacio.m),
      child: Semantics(
        liveRegion: true,
        label: borrador.isEmpty
            ? 'Escuchando. Todavía no he entendido nada.'
            : 'Escuchando: $borrador',
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: Row(
                children: [
                  for (final altura in [10.0, 18.0, 13.0, 22.0, 12.0]) ...[
                    Container(
                      width: 3,
                      height: altura,
                      decoration: BoxDecoration(
                        color: paleta.acento,
                        borderRadius: BorderRadius.circular(radioPildora),
                      ),
                    ),
                    const SizedBox(width: Espacio.xs),
                  ],
                ],
              ),
            ),
            const SizedBox(width: Espacio.s),
            Expanded(
              child: Text(
                borrador.isEmpty ? 'Escuchando…' : borrador,
                style: tema.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorVoz extends StatelessWidget {
  const _ErrorVoz(this.mensaje);

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Espacio.m),
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ExcludeSemantics(child: Icon(Icons.info_outline, size: 16)),
            const SizedBox(width: Espacio.s),
            Expanded(child: Text(mensaje, style: tema.textTheme.bodySmall)),
          ],
        ),
      ),
    );
  }
}
