/// Notificador del estado compartido. Sección 3 · sección 8.
///
/// Cada cambio se guarda en el almacén local; nada viaja fuera del
/// dispositivo (RNF-01).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dominio/logica/hidratacion.dart';
import '../dominio/modelos/enums.dart';
import '../dominio/modelos/perfil.dart';
import '../dominio/modelos/plan_comidas.dart';
import '../servicios/contratos/contratos.dart';
import '../servicios/impl/generador_rutina_ia.dart';
import 'estado_app.dart';
import 'proveedores.dart';

/// Pasos del indicador «generando» de la rutina de Entreno (mismo patrón que
/// Dieta, RF-15).
const List<String> pasosDeGeneracionRutina = [
  'Pensando ejercicios para hoy',
  'Ajustando tiempos y descansos',
  'Revisando que todo tenga sentido',
];

/// Pausa entre pasos del indicador «generando» (RF-15).
const Duration pausaEntrePasosGeneracion = Duration(milliseconds: 320);

class NotificadorApp extends Notifier<EstadoApp> {
  @override
  EstadoApp build() => ref.watch(estadoInicialProvider);

  Almacen get _almacen => ref.read(almacenProvider);

  Reloj get _reloj => ref.read(relojProvider);

  MotorIA get _motor => ref.read(motorIaProvider);

  Future<void> _guardarPerfil(Perfil perfil) async {
    // El plan depende de (peso, tasa, preferencia): si cambian, deja de estar
    // en uso y Dieta pedirá regenerarlo (sección 5 · reglas de integridad).
    state = state.copiarCon(perfil: perfil, planUsadoHoy: false);
    await _almacen.guardarPerfil(perfil);
  }

  /// Igual que [_guardarPerfil] pero sin tocar `planUsadoHoy`: para cambios
  /// que no entran en [EstadoApp.planVigente] (comidasFavoritas,
  /// ingredientesEvitar), invalidar el plan en uso sería un efecto
  /// secundario sin motivo.
  Future<void> _guardarPerfilPreservandoPlan(Perfil perfil) async {
    state = state.copiarCon(perfil: perfil);
    await _almacen.guardarPerfil(perfil);
  }

  Future<void> _guardarPreferencias(Preferencias preferencias) async {
    state = state.copiarCon(preferencias: preferencias);
    await _almacen.guardarPreferencias(preferencias);
  }

  // --- Perfil y onboarding -------------------------------------------------

  Future<void> cambiarPeso(double kg) =>
      _guardarPerfil(state.perfil.copiarCon(pesoKg: acotarPeso(kg)));

  Future<void> cambiarAltura(double cm) =>
      _guardarPerfil(state.perfil.copiarCon(alturaCm: acotarAltura(cm)));

  /// Al elegir objetivo se arrastra su tasa sugerida; luego puede ajustarse
  /// a mano en Dieta (resolución del Anexo A).
  Future<void> cambiarObjetivo(Objetivo objetivo) =>
      _guardarPerfil(state.perfil.conObjetivo(objetivo));

  Future<void> cambiarTasa(TasaProteina tasa) =>
      _guardarPerfil(state.perfil.copiarCon(tasaProteina: tasa));

  Future<void> cambiarPreferenciaDieta(PreferenciaDieta preferencia) =>
      _guardarPerfil(state.perfil.copiarCon(preferenciaDieta: preferencia));

  /// Comidas o ingredientes que le gustan a la persona (sección 4.3). Sesga
  /// el catálogo y el pedido a la IA; nunca cambia la proteína objetivo, así
  /// que a diferencia de [cambiarPreferenciaDieta] no invalida el plan del
  /// día (`planUsadoHoy` se conserva).
  Future<void> cambiarComidasFavoritas(String texto) => _guardarPerfilPreservandoPlan(
        state.perfil.copiarCon(comidasFavoritas: texto),
      );

  /// Ingredientes que la persona no quiere ver en sus comidas (sección 4.3).
  Future<void> cambiarIngredientesEvitar(String texto) => _guardarPerfilPreservandoPlan(
        state.perfil.copiarCon(ingredientesEvitar: texto),
      );

  Future<void> cambiarUnidades(Unidades unidades) =>
      _guardarPreferencias(state.preferencias.copiarCon(unidades: unidades));

  Future<void> cambiarTema(TemaApp tema) =>
      _guardarPreferencias(state.preferencias.copiarCon(tema: tema));

  Future<void> alternarNecesidad(Necesidad necesidad) =>
      _guardarPreferencias(state.preferencias.alternarNecesidad(necesidad));

  /// Cierra el onboarding: solo se muestra una vez (RF-01).
  Future<void> completarOnboarding() =>
      _guardarPreferencias(
        state.preferencias.copiarCon(onboardingCompletado: true),
      );

  // --- Hidratación ---------------------------------------------------------

  /// Registra agua respetando el tope diario (RF-30).
  Future<void> registrarAgua(int incrementoMl) async {
    final nuevo = registrarAguaDelDia(
      actualMl: state.aguaMl,
      incrementoMl: incrementoMl,
    );
    if (nuevo == state.aguaMl) return;
    state = state.copiarCon(aguaMl: nuevo);
    await _almacen.guardarAgua(state.dia, nuevo);
  }

  // --- Plan de comidas -----------------------------------------------------

  /// Genera el plan mostrando los pasos de «generando» (RF-15, RF-22, RF-24).
  Future<void> generarPlan({bool regenerar = false}) async {
    if (state.generandoPlan) return;
    state = state.copiarCon(generandoPlan: true, pasoGeneracion: 0);

    final pasos = _motor.pasosDeGeneracion;
    for (var i = 0; i < pasos.length; i++) {
      state = state.copiarCon(pasoGeneracion: i);
      await Future<void>.delayed(pausaEntrePasosGeneracion);
    }

    final plan = await _motor.generarPlan(
      pesoKg: state.perfil.pesoKg,
      tasa: state.perfil.tasaProteina,
      preferencia: state.perfil.preferenciaDieta,
      semilla: regenerar
          ? _reloj.ahora().millisecondsSinceEpoch
          : state.dia.millisecondsSinceEpoch,
      comidasFavoritas: state.perfil.comidasFavoritas,
      ingredientesEvitar: state.perfil.ingredientesEvitar,
    );

    state = state.copiarCon(
      plan: plan,
      generandoPlan: false,
      pasoGeneracion: 0,
      planUsadoHoy: false,
    );
    await _almacen.guardarPlan(plan);
  }

  /// «Usar en el día» (RF-24).
  void usarPlanEnElDia() {
    if (state.plan == null) return;
    state = state.copiarCon(planUsadoHoy: true);
  }

  /// Adopta el plan que ha propuesto el asistente en Inicio (RF-13).
  ///
  /// Sin esto el plan viviría solo dentro del mensaje y Dieta seguiría vacía:
  /// hay una sola fuente de estado, así que el plan tiene que pasar por aquí.
  Future<void> adoptarPlan(PlanComidas plan) async {
    state = state.copiarCon(plan: plan, planUsadoHoy: true);
    await _almacen.guardarPlan(plan);
  }

  // --- Rutina del día por IA -------------------------------------------

  /// Genera la rutina de hoy con IA (sección 4.5). A diferencia del plan de
  /// comidas, aquí el ejercicio en sí también lo decide el modelo, no solo
  /// el nombre: la persona lo pidió así. Si el modelo no está listo o la
  /// respuesta no es válida, no se toca [EstadoApp.rutinaIA] y Entreno sigue
  /// mostrando el catálogo fijo (rutinaDelDiaProvider ya hace esa caída).
  Future<void> generarRutinaIA({bool regenerar = false}) async {
    if (state.generandoRutina) return;
    state = state.copiarCon(
      generandoRutina: true,
      pasoGeneracionRutina: 0,
      limpiarRutinaIAError: true,
    );

    for (var i = 0; i < pasosDeGeneracionRutina.length; i++) {
      state = state.copiarCon(pasoGeneracionRutina: i);
      await Future<void>.delayed(pausaEntrePasosGeneracion);
    }

    // Sin esta distinción, un modelo todavía no listo y una generación que
    // falla de verdad se veían exactamente igual desde fuera: nada cambiaba
    // en pantalla y no había pista de por qué.
    if (ref.read(gestorModeloIAProvider).estado != EstadoModeloIA.listo) {
      state = state.copiarCon(
        generandoRutina: false,
        pasoGeneracionRutina: 0,
        rutinaIAError: 'El modelo de IA todavía no está listo. Revisa su '
            'estado en Perfil → IA local.',
      );
      return;
    }

    final rutina = await generarRutinaConIA(
      generador: ref.read(generadorContenidoIAProvider),
      objetivo: state.perfil.objetivo,
      id: 'ia-${state.dia.year}-${state.dia.month}-${state.dia.day}'
          '-${_reloj.ahora().millisecondsSinceEpoch}',
    );

    if (rutina != null) {
      state = state.copiarCon(
        rutinaIA: rutina,
        generandoRutina: false,
        pasoGeneracionRutina: 0,
      );
      await _almacen.guardarRutinaIA(state.dia, rutina);
    } else {
      state = state.copiarCon(
        generandoRutina: false,
        pasoGeneracionRutina: 0,
        rutinaIAError: 'No se pudo generar una rutina esta vez. Se '
            'mantiene la de siempre; puedes volver a intentarlo.',
      );
    }
  }

  // --- Ciclo de vida diario ------------------------------------------------

  /// Comprueba si ha cambiado el día para reiniciar agua y plan (sección 5).
  ///
  /// Devuelve `true` si hubo cambio, para que la conversación también se
  /// vacíe (RF-16).
  Future<bool> comprobarCambioDeDia() async {
    final ahora = _reloj.ahora();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    if (hoy == state.dia) return false;

    state = state.copiarCon(
      dia: hoy,
      aguaMl: await _almacen.leerAgua(hoy),
      limpiarPlan: true,
      planUsadoHoy: false,
      limpiarRutinaIA: true,
    );
    return true;
  }

  // --- Privacidad ----------------------------------------------------------

  /// Volcado legible de todo lo guardado (RF-52).
  Future<String> exportarDatos() => _almacen.exportar();

  // --- IA local -------------------------------------------------------

  /// Guarda la URL del modelo de IA descargado, para restaurarlo sin volver
  /// a descargarlo la próxima vez que se abra la app. `null` la olvida.
  Future<void> recordarModeloIA(String? url) =>
      _almacen.guardarUrlModeloIA(url);

  /// «Borrar mis datos»: deja la app como recién instalada.
  Future<void> borrarDatos() async {
    await _almacen.borrarTodo();
    final ahora = _reloj.ahora();
    state = EstadoApp(
      perfil: Perfil.inicial(),
      preferencias: Preferencias.inicial(),
      dia: DateTime(ahora.year, ahora.month, ahora.day),
    );
  }
}

/// Alias para no tapar el método del notificador con la función del dominio.
int registrarAguaDelDia({required int actualMl, required int incrementoMl}) =>
    registrarAgua(actualMl: actualMl, incrementoMl: incrementoMl);

final estadoAppProvider =
    NotifierProvider<NotificadorApp, EstadoApp>(NotificadorApp.new);
