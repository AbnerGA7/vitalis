/// Orbe del asistente. Sección 7 · ADR-07 · RNF-05, AC-06.
///
/// Decisión para v1: animación ligera dibujada con `CustomPaint` en vez de
/// WebGL. Cuesta mucha menos batería en gama media y baja, funciona sin
/// contexto gráfico adicional y se apaga solo cuando el sistema pide
/// movimiento reducido. Es decorativo: va siempre acompañado de texto y
/// oculto al lector de pantalla (AC-06).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/nocturne_tema.dart';
import 'indicadores.dart';

/// Estados del orbe descritos en la sección 7.
enum EstadoOrbe { reposo, escuchando, hablando }

class Orbe extends StatefulWidget {
  const Orbe({
    super.key,
    this.estado = EstadoOrbe.reposo,
    this.energia = 0.4,
    this.diametro = 96,
  });

  final EstadoOrbe estado;

  /// Nivel de energía, entre 0 y 1.
  final double energia;

  final double diametro;

  @override
  State<Orbe> createState() => _OrbeState();
}

class _OrbeState extends State<Orbe> with SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void initState() {
    super.initState();
    _controlador.repeat();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final reducido = movimientoReducido(context);

    // Con movimiento reducido el orbe se queda quieto (RNF-05).
    if (reducido && _controlador.isAnimating) {
      _controlador.stop();
    } else if (!reducido && !_controlador.isAnimating) {
      _controlador.repeat();
    }

    // Cada estado tiene su ritmo: respira, rebota u ondea.
    final ritmo = switch (widget.estado) {
      EstadoOrbe.reposo => 1.0,
      EstadoOrbe.escuchando => 2.4,
      EstadoOrbe.hablando => 3.6,
    };

    return ExcludeSemantics(
      child: SizedBox(
        width: widget.diametro,
        height: widget.diametro,
        child: AnimatedBuilder(
          animation: _controlador,
          builder: (context, _) {
            final fase = reducido ? 0.0 : _controlador.value * ritmo;
            return CustomPaint(
              painter: _PintorOrbe(
                fase: fase,
                energia: widget.energia.clamp(0, 1),
                centro: paleta.acento,
                halo: paleta.acentoSuave,
                brillo: paleta.texto,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PintorOrbe extends CustomPainter {
  _PintorOrbe({
    required this.fase,
    required this.energia,
    required this.centro,
    required this.halo,
    required this.brillo,
  });

  final double fase;
  final double energia;
  final Color centro;
  final Color halo;
  final Color brillo;

  @override
  void paint(Canvas canvas, Size size) {
    final medio = size.center(Offset.zero);
    final pulso = math.sin(fase * math.pi * 2) * 0.5 + 0.5;
    final radioBase = size.width / 2 * (0.72 + 0.06 * energia);
    final radio = radioBase * (0.94 + 0.06 * pulso);

    // Halo suave, sin inundar de acento (sección 7 · reglas).
    canvas.drawCircle(
      medio,
      radio * 1.28,
      Paint()..color = halo.withValues(alpha: 0.5),
    );

    canvas.drawCircle(
      medio,
      radio,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [
            Color.lerp(brillo, centro, 0.25)!,
            centro,
            Color.lerp(centro, halo, 0.6)!,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: medio, radius: radio)),
    );
  }

  @override
  bool shouldRepaint(_PintorOrbe anterior) =>
      anterior.fase != fase ||
      anterior.energia != energia ||
      anterior.centro != centro;
}
