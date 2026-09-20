/// Onboarding de tres pasos. Sección 3 · RF-01…RF-06.
///
/// Se muestra una sola vez; al terminar se entra a Inicio.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nocturne_tokens.dart';
import '../../estado/notificador_app.dart';
import '../widgets/componentes.dart';
import 'paso_cuerpo.dart';
import 'paso_privacidad.dart';
import 'paso_resumen.dart';

class PantallaOnboarding extends ConsumerStatefulWidget {
  const PantallaOnboarding({super.key});

  @override
  ConsumerState<PantallaOnboarding> createState() => _PantallaOnboardingState();
}

class _PantallaOnboardingState extends ConsumerState<PantallaOnboarding> {
  static const int _totalPasos = 3;
  int _paso = 0;

  void _siguiente() {
    if (_paso < _totalPasos - 1) {
      setState(() => _paso++);
    } else {
      ref.read(estadoAppProvider.notifier).completarOnboarding();
    }
  }

  void _atras() {
    if (_paso > 0) setState(() => _paso--);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final etiquetaPaso = 'Paso ${_paso + 1} de $_totalPasos';

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Espacio.l,
                Espacio.l,
                Espacio.l,
                Espacio.s,
              ),
              child: Row(
                children: [
                  if (_paso > 0)
                    Semantics(
                      button: true,
                      label: 'Volver al paso anterior',
                      excludeSemantics: true,
                      child: IconButton(
                        onPressed: _atras,
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        etiquetaPaso,
                        style: tema.textTheme.labelMedium,
                        textAlign: _paso > 0 ? TextAlign.center : TextAlign.start,
                      ),
                    ),
                  ),
                  if (_paso > 0) const SizedBox(width: areaTactilMinima),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Espacio.l,
                  Espacio.s,
                  Espacio.l,
                  Espacio.l,
                ),
                child: switch (_paso) {
                  0 => const PasoPrivacidad(),
                  1 => const PasoCuerpo(),
                  _ => const PasoResumen(),
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Espacio.l),
              child: BotonVitalis(
                texto: _paso == _totalPasos - 1 ? 'Empezar' : 'Continuar',
                nombreAccesible: _paso == _totalPasos - 1
                    ? 'Empezar a usar Vitalis'
                    : 'Continuar al paso ${_paso + 2} de $_totalPasos',
                ocuparAncho: true,
                onPressed: _siguiente,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
