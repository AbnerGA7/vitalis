/// Montaje común de las pruebas de estado e interfaz.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitalis/core/nocturne_tema.dart';
import 'package:vitalis/dominio/modelos/enums.dart';
import 'package:vitalis/dominio/modelos/perfil.dart';
import 'package:vitalis/estado/estado_app.dart';
import 'package:vitalis/estado/proveedores.dart';
import 'package:vitalis/servicios/contratos/contratos.dart';

import 'dobles.dart';

/// Pide «movimiento reducido» durante la prueba (RNF-05).
///
/// Además de comprobar que la app lo respeta, deja quieto el orbe para que
/// `pumpAndSettle` pueda converger.
void usarMovimientoReducido() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// Todo lo que una prueba necesita sustituir.
class Entorno {
  Entorno({
    DateTime? ahora,
    Perfil? perfil,
    Preferencias? preferencias,
    int aguaMl = 0,
    bool hayDictado = true,
    EstadoModeloIA estadoModeloIA = EstadoModeloIA.sinInstalar,
  })  : reloj = RelojFalso(ahora ?? DateTime(2026, 9, 19, 9)),
        voz = VozFalsa(hayDictado: hayDictado),
        gestorModeloIA = GestorModeloIAFalso(estado: estadoModeloIA) {
    final momento = reloj.ahora();
    estadoInicial = EstadoApp(
      perfil: perfil ?? Perfil.inicial(),
      preferencias: preferencias ??
          Preferencias.inicial().copiarCon(onboardingCompletado: true),
      dia: DateTime(momento.year, momento.month, momento.day),
      aguaMl: aguaMl,
    );
  }

  final RelojFalso reloj;
  final VozFalsa voz;
  final AlmacenFalso almacen = AlmacenFalso();
  final HapticoEspia haptico = HapticoEspia();
  final AnunciadorEspia anunciador = AnunciadorEspia();
  final GestorModeloIAFalso gestorModeloIA;
  final ConversadorIAFalso conversadorIA = ConversadorIAFalso();
  final SintesisVozEspia sintesisVoz = SintesisVozEspia();
  late final EstadoApp estadoInicial;

  List<Override> get overrides => [
        relojProvider.overrideWithValue(reloj),
        almacenProvider.overrideWithValue(almacen),
        estadoInicialProvider.overrideWithValue(estadoInicial),
        hapticoProvider.overrideWithValue(haptico),
        anunciadorProvider.overrideWithValue(anunciador),
        vozProvider.overrideWithValue(voz),
        gestorModeloIAProvider.overrideWithValue(gestorModeloIA),
        conversadorIAProvider.overrideWithValue(conversadorIA),
        sintesisVozProvider.overrideWithValue(sintesisVoz),
      ];

  ProviderContainer contenedor() {
    final contenedor = ProviderContainer(overrides: overrides);
    addTearDown(contenedor.dispose);
    return contenedor;
  }

  /// Monta la aplicación entera con los servicios simulados.
  Widget envolverApp(Widget aplicacion) =>
      ProviderScope(overrides: overrides, child: aplicacion);

  /// Envuelve un widget suelto con el tema y el ámbito de proveedores.
  Widget envolver(Widget hijo, {TemaApp tema = TemaApp.oscuro}) =>
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: temaNocturne(tema),
          home: hijo,
        ),
      );
}

/// Desplaza la pantalla indicada hasta dejar [objetivo] realmente visible.
///
/// Hace falta porque las listas construyen algo más allá del viewport: el
/// widget existe pero un toque sobre él erraría.
Future<void> desplazarHasta(
  WidgetTester tester,
  Finder objetivo, {
  required Finder dentroDe,
}) async {
  final desplazable =
      find.descendant(of: dentroDe, matching: find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(objetivo, 240, scrollable: desplazable);
  await tester.ensureVisible(objetivo);
  await tester.pumpAndSettle();
}

/// Toca un elemento asegurándose antes de que está realmente en pantalla.
Future<void> tocar(WidgetTester tester, Finder objetivo) async {
  await tester.ensureVisible(objetivo);
  await tester.pumpAndSettle();
  await tester.tap(objetivo);
}
