/// Raíz de la aplicación: tema, idioma y primera pantalla.
/// Sección 7 · RNF-07, RNF-08.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/nocturne_tema.dart';
import 'dominio/modelos/enums.dart';
import 'estado/notificador_app.dart';
import 'ui/cascaron.dart';
import 'ui/onboarding/pantalla_onboarding.dart';

class AplicacionVitalis extends ConsumerWidget {
  const AplicacionVitalis({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencias =
        ref.watch(estadoAppProvider.select((estado) => estado.preferencias));

    return MaterialApp(
      title: 'Vitalis',
      debugShowCheckedModeBanner: false,
      // Los dos temas comparten jerarquía; solo cambian los tokens (RNF-07).
      theme: temaNocturne(TemaApp.claro),
      darkTheme: temaNocturne(TemaApp.oscuro),
      themeMode: preferencias.tema == TemaApp.oscuro
          ? ThemeMode.dark
          : ThemeMode.light,
      // Español, con los textos de la interfaz en el código de cada pantalla
      // para poder externalizarlos cuando se añadan más idiomas (RNF-08).
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: preferencias.onboardingCompletado
          ? const Cascaron()
          : const PantallaOnboarding(),
    );
  }
}
