/// Ajuste de medidas corporales. RF-02 · AC-04.
library;

import 'package:flutter/material.dart';

import '../../core/nocturne_tema.dart';
import '../../core/nocturne_tokens.dart';

/// Control de una medida con incremento fijo.
///
/// El deslizador lleva divisiones de una unidad, de modo que el lector de
/// pantalla ofrece «aumentar» y «disminuir» de 1 kg o 1 cm (AC-04). Los dos
/// botones laterales hacen lo mismo para quien no puede arrastrar.
class AjustadorMedida extends StatelessWidget {
  const AjustadorMedida({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.minimo,
    required this.maximo,
    required this.onCambiar,
    required this.textoValor,
    required this.nombreUnidad,
  });

  final String etiqueta;
  final double valor;
  final double minimo;
  final double maximo;
  final ValueChanged<double> onCambiar;

  /// Valor ya formateado para la vista, p. ej. «72 kg» o «5 ft 9 in».
  final String textoValor;

  /// Unidad en palabras, para el lector de pantalla: «kilos», «centímetros».
  final String nombreUnidad;

  void _ajustar(double delta) {
    final nuevo = (valor + delta).clamp(minimo, maximo);
    if (nuevo != valor) onCambiar(nuevo);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final divisiones = (maximo - minimo).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(etiqueta, style: tema.textTheme.labelMedium),
            Text(textoValor, style: tema.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: Espacio.xs),
        Row(
          children: [
            _BotonAjuste(
              icono: Icons.remove,
              nombre: 'Disminuir $etiqueta en 1 $nombreUnidad',
              onPulsar: () => _ajustar(-1),
            ),
            Expanded(
              child: Slider(
                value: valor.clamp(minimo, maximo),
                min: minimo,
                max: maximo,
                divisions: divisiones,
                label: textoValor,
                onChanged: (nuevo) => onCambiar(nuevo.roundToDouble()),
                semanticFormatterCallback: (valor) =>
                    '${valor.round()} $nombreUnidad',
              ),
            ),
            _BotonAjuste(
              icono: Icons.add,
              nombre: 'Aumentar $etiqueta en 1 $nombreUnidad',
              onPulsar: () => _ajustar(1),
            ),
          ],
        ),
      ],
    );
  }
}

class _BotonAjuste extends StatelessWidget {
  const _BotonAjuste({
    required this.icono,
    required this.nombre,
    required this.onPulsar,
  });

  final IconData icono;
  final String nombre;
  final VoidCallback onPulsar;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Semantics(
      button: true,
      label: nombre,
      excludeSemantics: true,
      child: SizedBox(
        width: areaTactilMinima,
        height: areaTactilMinima,
        child: IconButton(
          onPressed: onPulsar,
          icon: Icon(icono),
          style: IconButton.styleFrom(
            side: BorderSide(color: paleta.borde),
            shape: const CircleBorder(),
          ),
        ),
      ),
    );
  }
}
