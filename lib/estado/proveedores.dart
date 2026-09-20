/// Cableado de servicios y notificadores. Sección 8.
///
/// Todo servicio se expone detrás de su contrato, así que en pruebas basta
/// con sustituir el proveedor por un doble.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dominio/catalogo/rutinas.dart';
import '../servicios/contratos/contratos.dart';
import '../servicios/impl/dispositivo.dart';
import '../servicios/impl/motor_ia_local.dart';
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

/// Motor de IA local. Recibe el contexto del estado compartido, de forma que
/// cambiar el peso en Perfil cambia también lo que responde el asistente.
final motorIaProvider = Provider<MotorIA>((ref) {
  return MotorIALocal(
    reloj: ref.watch(relojProvider),
    obtenerContexto: () {
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
      );
    },
  );
});

/// Rutina recomendada del día, derivada del estado compartido (RF-40).
final rutinaDelDiaProvider = Provider((ref) {
  final estado = ref.watch(estadoAppProvider);
  return rutinaRecomendada(
    objetivo: estado.perfil.objetivo,
    preferencias: estado.preferencias,
    fecha: estado.dia,
  );
});
