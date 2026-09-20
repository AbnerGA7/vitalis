/// Controles de elección y ajuste. Sección 7 · AC-01, AC-04, AC-05, AC-09.
library;

import 'package:flutter/material.dart';

import '../../core/nocturne_tema.dart';
import '../../core/nocturne_tokens.dart';

/// Casilla con texto y estado. Nunca un chip solo con icono (AC-05).
class CasillaNecesidad extends StatelessWidget {
  const CasillaNecesidad({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.marcada,
    required this.onCambiar,
  });

  final String titulo;
  final String descripcion;
  final bool marcada;
  final ValueChanged<bool> onCambiar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final paleta = context.paleta;
    return Semantics(
      checked: marcada,
      label: '$titulo. $descripcion',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onCambiar(!marcada),
        borderRadius: BorderRadius.circular(radioTarjeta),
        child: Container(
          constraints: const BoxConstraints(minHeight: areaTactilMinima),
          padding: const EdgeInsets.all(Espacio.m),
          decoration: BoxDecoration(
            color: marcada ? paleta.acentoSuave : paleta.superficie,
            borderRadius: BorderRadius.circular(radioTarjeta),
            border: Border.all(
              color: marcada ? paleta.acento : paleta.borde,
              width: marcada ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(value: marcada, onChanged: (v) => onCambiar(v ?? false)),
              const SizedBox(width: Espacio.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: tema.textTheme.titleSmall),
                    const SizedBox(height: Espacio.xs),
                    Text(descripcion, style: tema.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opción de un control segmentado.
class OpcionSegmento<T> {
  const OpcionSegmento({
    required this.valor,
    required this.etiqueta,
    this.nombreAccesible,
  });

  final T valor;
  final String etiqueta;
  final String? nombreAccesible;
}

/// Control segmentado con área táctil de 48 dp por opción (AC-01).
class ControlSegmentado<T> extends StatelessWidget {
  const ControlSegmentado({
    super.key,
    required this.opciones,
    required this.seleccionado,
    required this.onElegir,
    required this.etiquetaGrupo,
  });

  final List<OpcionSegmento<T>> opciones;
  final T seleccionado;
  final ValueChanged<T> onElegir;

  /// Nombre del grupo, para que el lector diga de qué se está eligiendo.
  final String etiquetaGrupo;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Semantics(
      label: etiquetaGrupo,
      container: true,
      child: Wrap(
        spacing: Espacio.s,
        runSpacing: Espacio.s,
        children: [
          for (final opcion in opciones)
            Semantics(
              inMutuallyExclusiveGroup: true,
              selected: opcion.valor == seleccionado,
              label: opcion.nombreAccesible ?? opcion.etiqueta,
              excludeSemantics: true,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: areaTactilMinima,
                  minWidth: areaTactilMinima,
                ),
                child: OutlinedButton(
                  onPressed: () => onElegir(opcion.valor),
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    backgroundColor: opcion.valor == seleccionado
                        ? paleta.acentoSuave
                        : Colors.transparent,
                    side: BorderSide(
                      color: opcion.valor == seleccionado
                          ? paleta.acento
                          : paleta.borde,
                      width: opcion.valor == seleccionado ? 1.5 : 1,
                    ),
                    foregroundColor: opcion.valor == seleccionado
                        ? paleta.acento
                        : paleta.texto,
                  ),
                  child: Text(opcion.etiqueta),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
