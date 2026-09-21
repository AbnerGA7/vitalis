/// Cableado de servicios y notificadores. Sección 8.
///
/// Todo servicio se expone detrás de su contrato, así que en pruebas basta
/// con sustituir el proveedor por un doble.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dominio/catalogo/rutinas.dart';
import '../servicios/contratos/contratos.dart';
import '../servicios/impl/conversador_gemma.dart';
import '../servicios/impl/dispositivo.dart';
import '../servicios/impl/generador_contenido_gemma.dart';
import '../servicios/impl/motor_ia_hibrido.dart';
import '../servicios/impl/motor_ia_local.dart';
import '../servicios/impl/sintesis_voz_sistema.dart';
import '../servicios/impl/voz_sistema.dart';
import 'estado_app.dart';
import 'notificador_app.dart';

/// Reloj del sistema. Se sustituye en pruebas por uno simulado (RNF-06).
final relojProvider = Provider<Reloj>((ref) => const RelojSistema());

/// Almacén local. `main` lo sustituye por la instancia ya abierta.
final almacenProvider = Provider<Almacen>((ref) {
  throw UnimplementedError(
    'almacenProvider debe sobrescribirse al arrancar la aplicación.',
  );
});

/// Estado inicial ya leído del almacén. `main` lo sustituye.
final estadoInicialProvider = Provider<EstadoApp>((ref) {
  throw UnimplementedError(
    'estadoInicialProvider debe sobrescribirse al arrancar la aplicación.',
  );
});

final anunciadorProvider =
    Provider<Anunciador>((ref) => const AnunciadorSemantics());

/// Háptica del dispositivo.
///
/// El proveedor solo ofrece la capacidad: quién vibra y cuándo lo decide cada
/// notificador según el requisito, porque no es la misma regla para el aviso
/// de fase (RF-61, solo si se declaró baja visión) que para el fin de
/// descanso (RF-45, obligatorio para todo el mundo).
final hapticoProvider = Provider<Haptico>((ref) => const HapticoFlutter());

final vozProvider = Provider<Voz>((ref) {
  final voz = VozSistema();
  ref.onDispose(voz.detener);
  return voz;
});

/// Voz de salida: el asistente lee sus respuestas en alto (chat de voz).
final sintesisVozProvider = Provider<SintesisVoz>((ref) {
  if (const bool.fromEnvironment('VITALIS_SIN_TTS', defaultValue: false)) {
    return const SintesisVozSilenciosa();
  }
  return SintesisVozSistema();
});

/// Ciclo de vida del modelo de IA local real: instalado / descargando / listo.
///
/// `main` lo sustituye por una instancia ya restaurada desde el almacén, para
/// que un modelo descargado en una sesión anterior siga listo al reabrir la
/// app sin tener que descargarlo otra vez.
final gestorModeloIAProvider = Provider<GestorModeloIA>((ref) {
  throw UnimplementedError(
    'gestorModeloIAProvider debe sobrescribirse al arrancar la aplicación.',
  );
});

/// Llamada cruda al modelo de lenguaje, detrás de su propio contrato para
/// poder simularla en pruebas sin tocar flutter_gemma.
final conversadorIAProvider =
    Provider<ConversadorIA>((ref) => ConversadorGemma());

/// Generación de contenido de una sola vuelta (recetas, ejercicios...),
/// detrás de su propio contrato para poder simularla en pruebas.
final generadorContenidoIAProvider =
    Provider<GeneradorContenidoIA>((ref) => GeneradorContenidoGemma());

/// Motor por reglas: siempre resuelve lo estructurado (plan/agua/entreno),
/// con o sin modelo de lenguaje real cargado.
final _motorReglasProvider = Provider<MotorIA>((ref) {
  return MotorIALocal(
    reloj: ref.watch(relojProvider),
    obtenerContexto: () => _contextoDesdeEstado(ref),
  );
});

/// Motor de IA local: reglas para lo estructurado, modelo real para la
/// conversación libre cuando hay uno cargado (ADR-03). Recibe el contexto del
/// estado compartido, de forma que cambiar el peso en Perfil cambia también
/// lo que responde el asistente.
final motorIaProvider = Provider<MotorIA>((ref) {
  return MotorIAHibrido(
    base: ref.watch(_motorReglasProvider),
    gestor: ref.watch(gestorModeloIAProvider),
    conversador: ref.watch(conversadorIAProvider),
    generador: ref.watch(generadorContenidoIAProvider),
    reloj: ref.watch(relojProvider),
    obtenerContexto: () => _contextoDesdeEstado(ref),
  );
});

ContextoAsistente _contextoDesdeEstado(Ref ref) {
  final estado = ref.read(estadoAppProvider);
  return ContextoAsistente(
    pesoKg: estado.perfil.pesoKg,
    tasa: estado.perfil.tasaProteina,
    preferencia: estado.perfil.preferenciaDieta,
    aguaMl: estado.aguaMl,
    nombreRutina: rutinaRecomendada(
      objetivo: estado.perfil.objetivo,
      preferencias: estado.preferencias,
      fecha: estado.dia,
    ).nombre,
    comidasFavoritas: estado.perfil.comidasFavoritas,
    ingredientesEvitar: estado.perfil.ingredientesEvitar,
  );
}

/// Rutina recomendada del día, derivada del estado compartido (RF-40).
///
/// Si hay una rutina de hoy generada por IA ([EstadoApp.rutinaIA]), esa gana;
/// si no, cae al catálogo fijo (sección 4.5).
final rutinaDelDiaProvider = Provider((ref) {
  final estado = ref.watch(estadoAppProvider);
  return estado.rutinaIA ??
      rutinaRecomendada(
        objetivo: estado.perfil.objetivo,
        preferencias: estado.preferencias,
        fecha: estado.dia,
      );
});
