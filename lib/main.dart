/// Arranque de Vitalis.
///
/// Se lee el estado guardado antes de pintar nada, así que la aplicación
/// aparece ya con los datos de la persona y sin parpadeo de carga.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'dominio/modelos/perfil.dart';
import 'estado/estado_app.dart';
import 'estado/proveedores.dart';
import 'servicios/impl/almacen_prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final almacen = await AlmacenPrefs.abrir();
  final ahora = DateTime.now();
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);

  final perfil = await almacen.leerPerfil() ?? Perfil.inicial();
  final preferencias =
      await almacen.leerPreferencias() ?? Preferencias.inicial();
  final agua = await almacen.leerAgua(hoy);

  // El plan es diario: si el guardado es de otro día, se descarta.
  final planGuardado = await almacen.leerPlan();
  final plan = planGuardado != null && planGuardado.fecha == hoy
      ? planGuardado
      : null;

  runApp(
    ProviderScope(
      overrides: [
        almacenProvider.overrideWithValue(almacen),
        estadoInicialProvider.overrideWithValue(
          EstadoApp(
            perfil: perfil,
            preferencias: preferencias,
            dia: hoy,
            plan: plan,
            aguaMl: agua,
          ),
        ),
      ],
      child: const AplicacionVitalis(),
    ),
  );
}
