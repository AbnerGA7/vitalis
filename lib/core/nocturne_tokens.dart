/// Tokens del sistema de diseño Nocturne. Sección 7.
///
/// Interfaz oscura, compacta y tranquila. Sin negro ni blanco puros, un solo
/// acento, jerarquía por tamaño y espacio en vez de por peso tipográfico.
library;

import 'package:flutter/material.dart';

/// Paleta de un tema concreto. El tema claro reasigna los mismos tokens,
/// sin tocar estilos individuales (sección 7 · Tema claro).
class PaletaNocturne {
  const PaletaNocturne({
    required this.fondo,
    required this.superficie,
    required this.superficieAlta,
    required this.texto,
    required this.textoSuave,
    required this.borde,
    required this.acento,
    required this.acentoSuave,
    required this.tintaSobreAcento,
  });

  /// Tema oscuro, el de partida y de mayor contraste (RNF-03, RNF-07).
  static const PaletaNocturne oscuro = PaletaNocturne(
    fondo: Color(0xFF121A2E),
    superficie: Color(0xFF1B2540),
    superficieAlta: Color(0xFF24315A),
    texto: Color(0xFFECEFF9),
    textoSuave: Color(0xFFAEB6CE),
    borde: Color(0xFF30406B),
    acento: Color(0xFF6FA8FF),
    acentoSuave: Color(0xFF1E3157),
    tintaSobreAcento: Color(0xFF0E1830),
  );

  /// Tema claro: mismos tokens, rampas invertidas.
  static const PaletaNocturne claro = PaletaNocturne(
    fondo: Color(0xFFF1F5FE),
    superficie: Color(0xFFFFFFFF),
    superficieAlta: Color(0xFFE6EDFB),
    texto: Color(0xFF121A2E),
    textoSuave: Color(0xFF4B5875),
    borde: Color(0xFFCFDBF2),
    acento: Color(0xFF2F62D6),
    acentoSuave: Color(0xFFE2EAFC),
    tintaSobreAcento: Color(0xFFFFFFFF),
  );

  final Color fondo;
  final Color superficie;
  final Color superficieAlta;
  final Color texto;
  final Color textoSuave;
  final Color borde;
  final Color acento;
  final Color acentoSuave;
  final Color tintaSobreAcento;
}

/// Verde funcional de Vitalis: fase de trabajo y destello de fin de descanso.
/// Es el mismo en ambos temas (sección 7 · Colores funcionales).
const Color verdeTrabajo = Color(0xFF3DDC97);

/// Tinta sobre el verde.
const Color tintaSobreVerde = Color(0xFF12211A);

/// Escala de espaciado con la densidad 0,70× de Nocturne.
///
/// La densidad afecta al espaciado, nunca al tamaño de las áreas táctiles:
/// esas siguen el mínimo de 48 dp de AC-01.
abstract final class Espacio {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 18;
  static const double xl = 26;
  static const double xxl = 36;
}

/// Radio de tarjetas y contenedores.
const double radioTarjeta = 8;

/// Radio de píldoras y chips.
const double radioPildora = 999;

/// Área táctil mínima (AC-01, RNF-02).
const double areaTactilMinima = 48;

/// Área del botón de micro (AC-01).
const double areaMicro = 64;

/// Grosor del anillo de foco visible (AC-09).
const double grosorFoco = 2;

/// Elevaciones. Sin sombras apiladas (sección 7).
List<BoxShadow> sombraSuave(PaletaNocturne paleta) => [
      BoxShadow(
        color: paleta.fondo.withValues(alpha: 0.45),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
