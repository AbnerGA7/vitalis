/// Cascarón de la aplicación: cuatro pestañas más la capa del reproductor.
/// Sección 3 · Mapa de navegación · RF-43.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/nocturne_tema.dart';
import '../estado/estado_conversacion.dart';
import '../estado/estado_entreno.dart';
import '../estado/notificador_app.dart';
import 'dieta/pantalla_dieta.dart';
import 'entreno/pantalla_entreno.dart';
import 'inicio/pantalla_inicio.dart';
import 'perfil/pantalla_perfil.dart';
import 'reproductor/capa_reproductor.dart';

/// Pestaña activa de la barra inferior.
final pestanaProvider = StateProvider<int>((ref) => 0);

class Cascaron extends ConsumerStatefulWidget {
  const Cascaron({super.key});

  @override
  ConsumerState<Cascaron> createState() => _CascaronState();
}

class _CascaronState extends ConsumerState<Cascaron>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    // Al volver a primer plano puede haber cambiado el día: entonces se
    // reinician agua y plan, y la conversación arranca vacía (RF-16).
    if (estado == AppLifecycleState.resumed) {
      _comprobarDia();
    }
  }

  Future<void> _comprobarDia() async {
    final cambio =
        await ref.read(estadoAppProvider.notifier).comprobarCambioDeDia();
    if (cambio && mounted) {
      ref.read(conversacionProvider.notifier).vaciar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pestana = ref.watch(pestanaProvider);
    final entrenoActivo =
        ref.watch(entrenoProvider.select((estado) => estado.activo));

    return Stack(
      children: [
        // Con el reproductor abierto, las pestañas quedan fuera de alcance
        // también para el lector de pantalla y el teclado: si no, seguirían
        // siendo un destino por error aunque no se vean (RF-43, WCAG 2.1.2).
        ExcludeSemantics(
          excluding: entrenoActivo,
          child: IgnorePointer(
            ignoring: entrenoActivo,
            child: Scaffold(
              body: IndexedStack(
                index: pestana,
                children: const [
                  PantallaInicio(),
                  PantallaDieta(),
                  PantallaEntreno(),
                  PantallaPerfil(),
                ],
              ),
              bottomNavigationBar: const _BarraInferior(),
            ),
          ),
        ),
        // El reproductor es una capa, no una pestaña: mientras se entrena no
        // hay navegación que distraiga ni destino por error (sección 3).
        if (entrenoActivo) const CapaReproductor(),
      ],
    );
  }
}

class _BarraInferior extends ConsumerWidget {
  const _BarraInferior();

  static const List<(IconData, String, String)> _destinos = [
    (Icons.auto_awesome_outlined, 'Inicio', 'Inicio, tu asistente'),
    (Icons.restaurant_outlined, 'Dieta', 'Dieta, tu plan de comidas y el agua'),
    (Icons.fitness_center_outlined, 'Entreno', 'Entreno, tus rutinas'),
    (Icons.person_outline, 'Perfil', 'Perfil, tus datos y adaptaciones'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paleta = context.paleta;
    final pestana = ref.watch(pestanaProvider);

    return NavigationBar(
      selectedIndex: pestana,
      onDestinationSelected: (indice) =>
          ref.read(pestanaProvider.notifier).state = indice,
      backgroundColor: paleta.superficie,
      indicatorColor: paleta.acentoSuave,
      surfaceTintColor: Colors.transparent,
      // Altura suficiente para mantener el área táctil por encima de 48 dp.
      height: 72,
      destinations: [
        for (final (icono, etiqueta, nombre) in _destinos)
          NavigationDestination(
            icon: Icon(icono),
            selectedIcon: Icon(icono, color: paleta.acento),
            label: etiqueta,
            tooltip: nombre,
          ),
      ],
    );
  }
}
