// Sección 9 · nivel «UI»: onboarding → Inicio; Inicio → plan → Dieta;
// Entreno → reproductor → salir.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis/app.dart';
import 'package:vitalis/dominio/modelos/perfil.dart';
import 'package:vitalis/ui/cascaron.dart';
import 'package:vitalis/ui/dieta/pantalla_dieta.dart';
import 'package:vitalis/ui/onboarding/pantalla_onboarding.dart';
import 'package:vitalis/ui/reproductor/capa_reproductor.dart';

import '../dobles/entorno.dart';

void main() {
  setUp(usarMovimientoReducido);

  testWidgets('el onboarding lleva a Inicio y no vuelve a salir',
      (tester) async {
    final entorno = Entorno(preferencias: Preferencias.inicial());
    await tester.pumpWidget(entorno.envolverApp(const AplicacionVitalis()));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaOnboarding), findsOneWidget);
    expect(find.text('Bienvenida a Vitalis'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Cuéntale a Vitalis sobre tu cuerpo'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Así queda tu Vitalis'), findsOneWidget);

    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();

    expect(find.byType(Cascaron), findsOneWidget);
    expect(find.byType(PantallaOnboarding), findsNothing);
    expect(entorno.almacen.preferencias?.onboardingCompletado, isTrue);
  });

  testWidgets('pedir el plan al asistente lleva a Dieta con el plan en uso',
      (tester) async {
    final entorno = Entorno();
    await tester.pumpWidget(entorno.envolverApp(const AplicacionVitalis()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'dame mi plan de comidas',
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pumpAndSettle();

    expect(find.text('Usar este plan'), findsOneWidget);

    await tester.ensureVisible(find.text('Usar este plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar este plan'));
    await tester.pumpAndSettle();

    // La acción cambia a la pestaña Dieta y marca el plan como en uso.
    await desplazarHasta(
      tester,
      find.text('Tu plan de hoy'),
      dentroDe: find.byType(PantallaDieta),
    );
    expect(find.text('Tu plan de hoy'), findsOneWidget);
    expect(find.text('En uso'), findsOneWidget);
  });

  testWidgets('empezar un entrenamiento abre la capa y salir la cierra',
      (tester) async {
    final entorno = Entorno();
    await tester.pumpWidget(entorno.envolverApp(const AplicacionVitalis()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entreno'));
    await tester.pumpAndSettle();

    await tocar(tester, find.text('Empezar entrenamiento'));
    await tester.pump();

    expect(find.byType(CapaReproductor), findsOneWidget);
    // Mientras se entrena no hay barra de navegación (sección 3).
    expect(find.byType(NavigationBar).hitTestable(), findsNothing);

    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();

    expect(find.byType(CapaReproductor), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(entorno.almacen.sesiones, hasLength(1));
  });

  testWidgets('el agua se registra desde Dieta y el texto se actualiza',
      (tester) async {
    final entorno = Entorno(aguaMl: 1000);
    await tester.pumpWidget(entorno.envolverApp(const AplicacionVitalis()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dieta'));
    await tester.pumpAndSettle();

    await desplazarHasta(
      tester,
      find.text('+250 ml'),
      dentroDe: find.byType(PantallaDieta),
    );
    await tester.tap(find.text('+250 ml'));
    await tester.pumpAndSettle();

    expect(find.text('1250'), findsOneWidget);
    expect(entorno.almacen.agua.values.first, 1250);
  });
}
