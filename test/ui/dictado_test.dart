// RF-10, RF-11 · AC-08, AC-11: voz y texto sobre el mismo estado.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis/app.dart';

import '../dobles/entorno.dart';

void main() {
  setUp(usarMovimientoReducido);

  testWidgets('lo dictado rellena el campo y queda editable antes de enviar',
      (tester) async {
    final entorno = Entorno();
    await tester.pumpWidget(entorno.envolverApp(const AplicacionVitalis()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pumpAndSettle();

    entorno.voz.transcribir('dame mi plan');
    await tester.pumpAndSettle();

    final campo = tester.widget<TextField>(find.byType(TextField));
    expect(campo.controller?.text, 'dame mi plan');

    // Sigue siendo un campo normal: se puede corregir antes de enviar.
    await tester.enterText(find.byType(TextField), 'dame mi plan de hoy');
    await tester.pumpAndSettle();
    expect(campo.controller?.text, 'dame mi plan de hoy');
  });

  testWidgets('escribir por el medio no mueve el cursor al final',
      (tester) async {
    final entorno = Entorno();
    await tester.pumpWidget(entorno.envolverApp(const AplicacionVitalis()));
    await tester.pumpAndSettle();

    final campo = find.byType(TextField);
    await tester.enterText(campo, 'plan de comidas');
    await tester.pumpAndSettle();

    // Se coloca el cursor tras «plan» y se escribe ahí.
    final controlador = tester.widget<TextField>(campo).controller!;
    controlador.selection = const TextSelection.collapsed(offset: 4);
    await tester.pumpAndSettle();

    expect(controlador.selection.baseOffset, 4);
  });

  testWidgets('el dictado vibra al abrir y al cerrar (AC-08)', (tester) async {
    final entorno = Entorno();
    await tester.pumpWidget(entorno.envolverApp(const AplicacionVitalis()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pumpAndSettle();
    expect(entorno.haptico.patrones, ['confirmacion']);

    await tester.tap(find.byIcon(Icons.stop));
    await tester.pumpAndSettle();
    expect(entorno.haptico.patrones, ['confirmacion', 'confirmacion']);
  });

  testWidgets('sin dictado se avisa y se puede seguir escribiendo',
      (tester) async {
    final entorno = Entorno(hayDictado: false);
    await tester.pumpWidget(entorno.envolverApp(const AplicacionVitalis()));
    await tester.pumpAndSettle();

    // Sin reconocimiento local no se ofrece el micro: la alternativa de texto
    // es la única vía y está siempre presente (AC-11).
    expect(find.byIcon(Icons.mic_none), findsNothing);

    await tester.enterText(find.byType(TextField), 'apunta un vaso de agua');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pumpAndSettle();

    expect(find.text('+250 ml'), findsOneWidget);
  });
}
