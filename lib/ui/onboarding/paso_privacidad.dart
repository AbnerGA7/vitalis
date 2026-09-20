/// Paso 1 del onboarding: bienvenida y privacidad. RF-06.
///
/// El prototipo dejaba este paso pendiente de diseño; aquí se implementa la
/// propuesta recogida en la sección 3: bienvenida más el aviso de que los
/// datos no salen del teléfono.
library;

import 'package:flutter/material.dart';

import '../../core/nocturne_tokens.dart';
import '../widgets/componentes.dart';
import '../widgets/orbe.dart';

class PasoPrivacidad extends StatelessWidget {
  const PasoPrivacidad({super.key});

  static const List<(IconData, String, String)> _garantias = [
    (
      Icons.wifi_off,
      'Funciona sin conexión',
      'No hace falta internet para nada de lo que ofrece la app.',
    ),
    (
      Icons.person_off_outlined,
      'Sin cuenta ni registro',
      'No hay contraseñas, ni correo, ni perfil que crear en ningún sitio.',
    ),
    (
      Icons.phone_android,
      'Tus datos se quedan aquí',
      'El peso, el plan y los entrenamientos viven solo en este teléfono. '
          'Si desinstalas la app, desaparecen con ella.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: Orbe(diametro: 120)),
        const SizedBox(height: Espacio.xl),
        Semantics(
          header: true,
          child: Text('Bienvenida a Vitalis', style: tema.textTheme.displaySmall),
        ),
        const SizedBox(height: Espacio.m),
        Text(
          'Vitalis te ayuda a entrenar, comer y beberte tu agua en casa. '
          'Está pensada desde el principio para adaptarse a cómo ves, oyes y '
          'te mueves.',
          style: tema.textTheme.bodyLarge,
        ),
        const SizedBox(height: Espacio.xl),
        TarjetaVitalis(
          resumenAccesible: 'Privacidad: Vitalis funciona sin conexión, sin '
              'cuenta y sin enviar tus datos a ningún sitio. Todo se guarda en '
              'este teléfono y desaparece si desinstalas la app.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (icono, titulo, detalle) in _garantias) ...[
                _Garantia(icono: icono, titulo: titulo, detalle: detalle),
                if (titulo != _garantias.last.$2)
                  const SizedBox(height: Espacio.l),
              ],
            ],
          ),
        ),
        const SizedBox(height: Espacio.l),
        Text(
          'Lo que viene ahora son dos pasos cortos: tus medidas y qué '
          'adaptaciones quieres. Podrás cambiarlo todo después desde Perfil.',
          style: tema.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Garantia extends StatelessWidget {
  const _Garantia({
    required this.icono,
    required this.titulo,
    required this.detalle,
  });

  final IconData icono;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Icon(icono, size: 20)),
        const SizedBox(width: Espacio.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: tema.textTheme.titleSmall),
              const SizedBox(height: Espacio.xs),
              Text(detalle, style: tema.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
