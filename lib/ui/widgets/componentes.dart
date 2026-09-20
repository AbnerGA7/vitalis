/// Componentes base de Nocturne. Sección 7 · AC-01…AC-09.
library;

import 'package:flutter/material.dart';

import '../../core/nocturne_tema.dart';
import '../../core/nocturne_tokens.dart';

/// Tarjeta de Nocturne: superficie con borde, radio 8 y sin sombra apilada.
///
/// [resumenAccesible] hace que el lector de pantalla lea la tarjeta como un
/// solo nodo con su resumen completo (AC-03). Los hijos interactivos siguen
/// siendo alcanzables por separado.
class TarjetaVitalis extends StatelessWidget {
  const TarjetaVitalis({
    super.key,
    required this.child,
    this.resumenAccesible,
    this.padding = const EdgeInsets.all(Espacio.l),
    this.color,
    this.colorBorde,
  });

  final Widget child;
  final String? resumenAccesible;
  final EdgeInsets padding;
  final Color? color;
  final Color? colorBorde;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final contenido = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? paleta.superficie,
        borderRadius: BorderRadius.circular(radioTarjeta),
        border: Border.all(color: colorBorde ?? paleta.borde),
      ),
      child: child,
    );

    if (resumenAccesible == null) return contenido;
    return Semantics(
      container: true,
      label: resumenAccesible,
      child: contenido,
    );
  }
}

/// Título de sección: la jerarquía la hacen el tamaño y el espacio, no el peso.
class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.texto, {super.key, this.detalle});

  final String texto;
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(texto, style: tema.textTheme.headlineSmall),
        ),
        if (detalle != null) ...[
          const SizedBox(height: Espacio.xs),
          Text(detalle!, style: tema.textTheme.bodySmall),
        ],
      ],
    );
  }
}

/// Acción contorneada de Nocturne: borde de acento sobre transparente.
class BotonVitalis extends StatelessWidget {
  const BotonVitalis({
    super.key,
    required this.texto,
    required this.onPressed,
    this.icono,
    this.nombreAccesible,
    this.ocuparAncho = false,
  });

  final String texto;
  final VoidCallback? onPressed;
  final IconData? icono;

  /// Nombre propio para el lector de pantalla cuando el texto visible no basta
  /// por sí solo (AC-02).
  final String? nombreAccesible;

  final bool ocuparAncho;

  @override
  Widget build(BuildContext context) {
    final boton = OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: ocuparAncho ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 18),
            const SizedBox(width: Espacio.s),
          ],
          Flexible(child: Text(texto, textAlign: TextAlign.center)),
        ],
      ),
    );

    final envuelto = ocuparAncho
        ? SizedBox(width: double.infinity, child: boton)
        : boton;

    if (nombreAccesible == null) return envuelto;
    return Semantics(
      button: true,
      label: nombreAccesible,
      excludeSemantics: true,
      child: envuelto,
    );
  }
}

/// Píldora de acción rápida (40 dp de alto visual, 48 dp de área táctil).
class PildoraAccion extends StatelessWidget {
  const PildoraAccion({
    super.key,
    required this.texto,
    required this.nombreAccesible,
    required this.onPressed,
  });

  final String texto;

  /// «+250 ml» no basta: hace falta «Añadir 250 mililitros de agua» (AC-02).
  final String nombreAccesible;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Semantics(
      button: true,
      label: nombreAccesible,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: areaTactilMinima,
          minWidth: areaTactilMinima,
        ),
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            shape: const StadiumBorder(),
            side: BorderSide(color: paleta.acento),
            padding: const EdgeInsets.symmetric(horizontal: Espacio.l),
          ),
          child: Text(texto),
        ),
      ),
    );
  }
}
