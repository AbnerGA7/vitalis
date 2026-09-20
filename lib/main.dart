/// Arranque de Vitalis.
///
/// Se lee el estado guardado antes de pintar nada, así que la aplicación
/// aparece ya con los datos de la persona y sin parpadeo de carga.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'dominio/modelos/perfil.dart';
import 'estado/estado_app.dart';
import 'estado/proveedores.dart';
import 'servicios/contratos/contratos.dart';
import 'servicios/impl/almacen_prefs.dart';
import 'servicios/impl/gestor_modelo_gemma.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Registra el motor MediaPipe (ficheros .task) del modelo de IA local real
  // (ADR-03). No descarga nada por sí solo: solo deja el motor listo para
  // cuando GestorModeloGemma instale un modelo.
  await FlutterGemma.initialize(
    inferenceEngines: const [MediaPipeEngine()],
  );

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

  // Si en una sesión anterior se cambió al modelo empaquetado por otro
  // descargado por URL (vía avanzada en Perfil), se restaura ese en vez del
  // que trae la app (ADR-03).
  final gestorModeloIA = GestorModeloGemma();
  await gestorModeloIA.restaurar(await almacen.leerUrlModeloIA());

  // Sin eso, se instala el modelo que ya viene empaquetado en la app. No se
  // espera aquí: instalarlo tarda unos segundos y no debe retrasar la
  // primera pantalla. Mientras tanto el asistente sigue funcionando por
  // reglas y pasa a conversar libremente en cuanto el modelo queda listo.
  if (gestorModeloIA.estado != EstadoModeloIA.listo) {
    unawaited(gestorModeloIA.instalarModeloEmpaquetado());
  }

  runApp(
    ProviderScope(
      overrides: [
        almacenProvider.overrideWithValue(almacen),
        gestorModeloIAProvider.overrideWithValue(gestorModeloIA),
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
