/// Construcción de los temas de Material a partir de los tokens Nocturne.
/// Sección 7 · RNF-03, RNF-07, AC-09, AC-10.
library;

import 'package:flutter/material.dart';

import '../dominio/modelos/enums.dart';
import 'nocturne_tokens.dart';

const String _familiaInter = 'Inter';

/// Inter es variable: el peso se pide por el eje `wght`.
///
/// Nocturne no pasa de 500-600: la jerarquía la hacen el tamaño y el espacio.
TextStyle _inter(double tamano, int peso, Color color, {double? alto}) =>
    TextStyle(
      fontFamily: _familiaInter,
      fontSize: tamano,
      height: alto,
      color: color,
      fontVariations: [FontVariation('wght', peso.toDouble())],
      fontWeight: peso >= 600
          ? FontWeight.w600
          : (peso >= 500 ? FontWeight.w500 : FontWeight.w400),
    );

TextTheme _tipografia(PaletaNocturne paleta) => TextTheme(
      displaySmall: _inter(32, 600, paleta.texto, alto: 1.15),
      headlineMedium: _inter(26, 600, paleta.texto, alto: 1.2),
      headlineSmall: _inter(21, 600, paleta.texto, alto: 1.25),
      titleMedium: _inter(17, 500, paleta.texto, alto: 1.3),
      titleSmall: _inter(15, 500, paleta.texto, alto: 1.3),
      bodyLarge: _inter(16, 400, paleta.texto, alto: 1.5),
      bodyMedium: _inter(15, 400, paleta.texto, alto: 1.5),
      // Paso profundo de la rampa para el texto secundario (RNF-03).
      bodySmall: _inter(13, 400, paleta.textoSuave, alto: 1.45),
      labelLarge: _inter(15, 500, paleta.texto),
      labelMedium: _inter(13, 500, paleta.textoSuave),
    );

ThemeData temaNocturne(TemaApp tema) {
  final paleta =
      tema == TemaApp.oscuro ? PaletaNocturne.oscuro : PaletaNocturne.claro;
  final brillo = tema == TemaApp.oscuro ? Brightness.dark : Brightness.light;
  final tipografia = _tipografia(paleta);

  final bordeNormal = OutlineInputBorder(
    borderRadius: BorderRadius.circular(radioTarjeta),
    borderSide: BorderSide(color: paleta.borde),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brillo,
    fontFamily: _familiaInter,
    scaffoldBackgroundColor: paleta.fondo,
    canvasColor: paleta.fondo,
    // Densidad estándar a propósito: la densidad 0,70x de Nocturne se aplica
    // al espaciado, nunca al área táctil, que no baja de 48 dp (AC-01).
    visualDensity: VisualDensity.standard,
    colorScheme: ColorScheme(
      brightness: brillo,
      primary: paleta.acento,
      onPrimary: paleta.tintaSobreAcento,
      primaryContainer: paleta.acentoSuave,
      onPrimaryContainer: paleta.texto,
      secondary: verdeTrabajo,
      onSecondary: tintaSobreVerde,
      surface: paleta.superficie,
      onSurface: paleta.texto,
      surfaceContainerHighest: paleta.superficieAlta,
      onSurfaceVariant: paleta.textoSuave,
      outline: paleta.borde,
      error: const Color(0xFFE2787C),
      onError: paleta.tintaSobreAcento,
    ),
    textTheme: tipografia,
    dividerTheme: DividerThemeData(color: paleta.borde, thickness: 1),
    cardTheme: CardThemeData(
      color: paleta.superficie,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radioTarjeta),
        side: BorderSide(color: paleta.borde),
      ),
    ),
    // Acciones contorneadas: borde de acento sobre transparente, sin rellenos.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(areaTactilMinima, areaTactilMinima),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: Espacio.l, vertical: Espacio.m),
        ),
        textStyle: WidgetStatePropertyAll(tipografia.labelLarge),
        foregroundColor: WidgetStateProperty.resolveWith((estados) {
          if (estados.contains(WidgetState.disabled)) {
            return paleta.texto.withValues(alpha: 0.45);
          }
          return paleta.acento;
        }),
        side: WidgetStateProperty.resolveWith((estados) {
          if (estados.contains(WidgetState.disabled)) {
            return BorderSide(color: paleta.borde.withValues(alpha: 0.45));
          }
          return BorderSide(color: paleta.acento);
        }),
        overlayColor: WidgetStatePropertyAll(
          paleta.acento.withValues(alpha: 0.12),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radioTarjeta),
          ),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(areaTactilMinima, areaTactilMinima),
        ),
        foregroundColor: WidgetStatePropertyAll(paleta.acento),
        textStyle: WidgetStatePropertyAll(tipografia.labelLarge),
        overlayColor: WidgetStatePropertyAll(
          paleta.acento.withValues(alpha: 0.12),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(areaTactilMinima, areaTactilMinima),
        ),
        foregroundColor: WidgetStatePropertyAll(paleta.texto),
        overlayColor: WidgetStatePropertyAll(
          paleta.acento.withValues(alpha: 0.12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: paleta.superficie,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Espacio.m,
        vertical: Espacio.m,
      ),
      border: bordeNormal,
      enabledBorder: bordeNormal,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radioTarjeta),
        borderSide: BorderSide(color: paleta.acento, width: grosorFoco),
      ),
      hintStyle: tipografia.bodyMedium?.copyWith(color: paleta.textoSuave),
      labelStyle: tipografia.labelMedium,
    ),
    checkboxTheme: CheckboxThemeData(
      side: BorderSide(color: paleta.borde, width: 1.5),
      fillColor: WidgetStateProperty.resolveWith((estados) {
        if (estados.contains(WidgetState.selected)) return paleta.acento;
        return Colors.transparent;
      }),
      checkColor: WidgetStatePropertyAll(paleta.tintaSobreAcento),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: paleta.acento,
      linearTrackColor: paleta.superficieAlta,
      circularTrackColor: paleta.superficieAlta,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: paleta.superficieAlta,
      contentTextStyle: tipografia.bodyMedium,
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: paleta.superficie,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radioTarjeta),
        side: BorderSide(color: paleta.borde),
      ),
    ),
  );
}

/// Acceso rápido a la paleta desde cualquier widget.
extension PaletaDeContexto on BuildContext {
  PaletaNocturne get paleta =>
      Theme.of(this).brightness == Brightness.dark
          ? PaletaNocturne.oscuro
          : PaletaNocturne.claro;
}
