// Sección 9 · nivel «Accesibilidad»: criterios AC-01…AC-12.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis/app.dart';
import 'package:vitalis/dominio/modelos/enums.dart';
import 'package:vitalis/dominio/modelos/perfil.dart';
import 'package:vitalis/ui/cascaron.dart';
import 'package:vitalis/ui/dieta/pantalla_dieta.dart';
import 'package:vitalis/ui/perfil/pantalla_perfil.dart';

import '../dobles/entorno.dart';

/// Perfil con las dos necesidades a la vez: es el caso que la documentación
/// deja pendiente de probar (Anexo A).
Preferencias _ambasNecesidades() => Preferencias.inicial()
    .copiarCon(onboardingCompletado: true)
    .alternarNecesidad(Necesidad.hipoacusia)
    .alternarNecesidad(Necesidad.bajaVision);

void main() {
  setUp(usarMovimientoReducido);

  testWidgets('AC-01: las áreas táctiles llegan al mínimo en las 4 pestañas',
      (tester) async {
    final entorno = Entorno();
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(entorno.envolverApp(const AplicacionVitalis()));
    await tester.pumpAndSettle();

    for (final pestana in ['Inicio', 'Dieta', 'Entreno', 'Perfil']) {
      await tester.tap(find.text(pestana));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    }
    handle.dispose();
  });

  testWidgets('AC-02: todo control con toque tiene nombre accesible propio',
      (tester) async {
    final entorno = Entorno();
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(entorno.envolverApp(const AplicacionVitalis()));
    await tester.pumpAndSettle();

    for (final pestana in ['Inicio', 'Dieta', 'Entreno', 'Perfil']) {
      await tester.tap(find.text(pestana));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    }
    handle.dispose();
  });

  testWidgets('RNF-03: el contraste del texto pasa en ambos temas',
      (tester) async {
    for (final tema in TemaApp.values) {
      final entorno = Entorno(
        preferencias: Preferencias.inicial()
            .copiarCon(onboardingCompletado: true, tema: tema),
      );
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(entorno.envolverApp(const AplicacionVitalis()));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    }
  });

  testWidgets('AC-02: «+250 ml» se anuncia con su nombre completo',
      (tester) async {
    final entorno = Entorno();
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(entorno.envolverApp(const AplicacionVitalis()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dieta'));
    await tester.pumpAndSettle();
    await desplazarHasta(
      tester,
      find.text('+250 ml'),
      dentroDe: find.byType(PantallaDieta),
    );

    expect(
      find.bySemanticsLabel('Añadir 250 mililitros de agua'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Añadir 500 mililitros de agua'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('AC-04: el peso se ajusta de kilo en kilo con el lector',
      (tester) async {
    final entorno = Entorno();
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(entorno.envolverApp(const AplicacionVitalis()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    // Los dos botones laterales hacen de incremento explícito de 1 unidad.
    expect(find.bySemanticsLabel('Aumentar Peso en 1 kilo'), findsOneWidget);
    expect(find.bySemanticsLabel('Disminuir Peso en 1 kilo'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Aumentar Altura en 1 centímetro'),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel('Aumentar Peso en 1 kilo'));
    await tester.pumpAndSettle();
    expect(entorno.almacen.perfil?.pesoKg, 71);
    handle.dispose();
  });

  testWidgets('AC-05: las necesidades son casillas con texto y estado',
      (tester) async {
    final entorno = Entorno();
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(entorno.envolverApp(const AplicacionVitalis()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    for (final necesidad in Necesidad.values) {
      await desplazarHasta(
        tester,
        find.text(necesidad.etiqueta),
        dentroDe: find.byType(PantallaPerfil),
      );
      expect(find.text(necesidad.etiqueta), findsOneWidget);
      expect(find.text(necesidad.descripcion), findsOneWidget);
    }
    handle.dispose();
  });

  testWidgets('AC-11: sin dictado, la entrada de texto sigue disponible',
      (tester) async {
    final entorno = Entorno(hayDictado: false);
    await tester.pumpWidget(entorno.envolverApp(const AplicacionVitalis()));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.mic_none), findsNothing);
  });

  testWidgets('AC-12: con las dos necesidades se apilan subtítulo y vibración',
      (tester) async {
    final entorno = Entorno(preferencias: _ambasNecesidades());
    await tester.pumpWidget(entorno.envolverApp(const AplicacionVitalis()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entreno'));
    await tester.pumpAndSettle();
    await tocar(tester, find.text('Empezar entrenamiento'));
    await tester.pump();

    // Subtítulo de la señal sonora y gemela visual de la vibración, a la vez.
    expect(find.textContaining('[Trabajo]'), findsOneWidget);
    expect(find.text('Quedan 3 s'), findsOneWidget);
    expect(find.byIcon(Icons.vibration), findsOneWidget);

    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();
  });

  testWidgets('el reproductor no deja navegación alcanzable detrás',
      (tester) async {
    final entorno = Entorno();
    await tester.pumpWidget(entorno.envolverApp(const AplicacionVitalis()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entreno'));
    await tester.pumpAndSettle();
    await tocar(tester, find.text('Empezar entrenamiento'));
    await tester.pump();

    expect(find.byType(NavigationBar).hitTestable(), findsNothing);
    expect(find.bySemanticsLabel('Salir del entrenamiento'), findsOneWidget);

    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();
    expect(find.byType(Cascaron), findsOneWidget);
  });
}
