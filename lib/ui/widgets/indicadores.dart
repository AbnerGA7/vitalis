/// Indicadores decorativos: anillo, barra de pasos y orbe. Sección 7.
///
/// Todos van ocultos al lector de pantalla: la cifra o el texto de al lado es
/// la fuente accesible (AC-06). Todos respetan «movimiento reducido» (RNF-05).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/nocturne_tema.dart';
import '../../core/nocturne_tokens.dart';

/// ¿Ha pedido el sistema reducir el movimiento? (RNF-05, AC-10)
bool movimientoReducido(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

/// Anillo de progreso decorativo.
class AnilloProgreso extends StatelessWidget {
  const AnilloProgreso({
    super.key,
    required this.progreso,
    required this.child,
    this.diametro = 180,
    this.color,
  });

  final double progreso;
  final Widget child;
  final double diametro;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return ExcludeSemantics(
      child: SizedBox(
        width: diametro,
        height: diametro,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(diametro),
              painter: _PintorAnillo(
                progreso: progreso.clamp(0, 1),
                pista: paleta.superficieAlta,
                relleno: color ?? paleta.acento,
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _PintorAnillo extends CustomPainter {
  _PintorAnillo({
    required this.progreso,
    required this.pista,
    required this.relleno,
  });

  final double progreso;
  final Color pista;
  final Color relleno;

  @override
  void paint(Canvas canvas, Size size) {
    const grosor = 10.0;
    final centro = size.center(Offset.zero);
    final radio = (size.width - grosor) / 2;
    final rect = Rect.fromCircle(center: centro, radius: radio);

    final lapizPista = Paint()
      ..color = pista
      ..strokeWidth = grosor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final lapizRelleno = Paint()
      ..color = relleno
      ..strokeWidth = grosor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, lapizPista);
    if (progreso > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progreso,
        false,
        lapizRelleno,
      );
    }
  }

  @override
  bool shouldRepaint(_PintorAnillo anterior) =>
      anterior.progreso != progreso ||
      anterior.relleno != relleno ||
      anterior.pista != pista;
}

/// Barra de progreso por pasos de la rutina (RF-43).
class BarraPasos extends StatelessWidget {
  const BarraPasos({
    super.key,
    required this.total,
    required this.actual,
  });

  final int total;
  final int actual;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i < actual ? paleta.acento : paleta.superficieAlta,
                  borderRadius: BorderRadius.circular(radioPildora),
                ),
              ),
            ),
            if (i < total - 1) const SizedBox(width: Espacio.xs),
          ],
        ],
      ),
    );
  }
}
