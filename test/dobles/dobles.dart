/// Dobles de prueba de los servicios. Sección 8: los servicios se inyectan
/// detrás de interfaces precisamente para poder simularlos.
library;

import 'package:vitalis/dominio/modelos/perfil.dart';
import 'package:vitalis/dominio/modelos/plan_comidas.dart';
import 'package:vitalis/dominio/modelos/rutina.dart';
import 'package:vitalis/servicios/contratos/contratos.dart';

/// Reloj controlado desde la prueba (RNF-06).
class RelojFalso implements Reloj {
  RelojFalso(this._ahora);

  DateTime _ahora;

  @override
  DateTime ahora() => _ahora;

  void avanzar(Duration cuanto) => _ahora = _ahora.add(cuanto);

  void fijar(DateTime cuando) => _ahora = cuando;
}

/// Almacén en memoria: mismo contrato, sin tocar disco.
class AlmacenFalso implements Almacen {
  Perfil? perfil;
  Preferencias? preferencias;
  PlanComidas? plan;
  final Map<String, int> agua = {};
  final List<SesionEntreno> sesiones = [];

  @override
  Future<Perfil?> leerPerfil() async => perfil;

  @override
  Future<void> guardarPerfil(Perfil valor) async => perfil = valor;

  @override
  Future<Preferencias?> leerPreferencias() async => preferencias;

  @override
  Future<void> guardarPreferencias(Preferencias valor) async =>
      preferencias = valor;

  @override
  Future<PlanComidas?> leerPlan() async => plan;

  @override
  Future<void> guardarPlan(PlanComidas valor) async => plan = valor;

  @override
  Future<int> leerAgua(DateTime dia) async => agua[_clave(dia)] ?? 0;

  @override
  Future<void> guardarAgua(DateTime dia, int ml) async =>
      agua[_clave(dia)] = ml;

  @override
  Future<List<SesionEntreno>> leerSesiones() async => List.of(sesiones);

  @override
  Future<void> guardarSesion(SesionEntreno sesion) async =>
      sesiones.add(sesion);

  @override
  Future<String> exportar() async => '{"perfil":"simulado"}';

  @override
  Future<void> borrarTodo() async {
    perfil = null;
    preferencias = null;
    plan = null;
    agua.clear();
    sesiones.clear();
  }

  static String _clave(DateTime fecha) =>
      '${fecha.year}-${fecha.month}-${fecha.day}';
}

/// Háptico que apunta qué patrones se han disparado.
class HapticoEspia implements Haptico {
  final List<String> patrones = [];

  @override
  Future<void> inicioFase() async => patrones.add('inicio');

  @override
  Future<void> tresSegundos() async => patrones.add('t3');

  @override
  Future<void> finFase() async => patrones.add('fin');

  @override
  Future<void> confirmacion() async => patrones.add('confirmacion');
}

/// Anunciador que guarda lo dicho al lector de pantalla.
class AnunciadorEspia implements Anunciador {
  final List<String> mensajes = [];

  @override
  void anunciar(
    String mensaje, {
    PrioridadAnuncio prioridad = PrioridadAnuncio.educado,
  }) =>
      mensajes.add(mensaje);
}

/// Voz simulada: permite empujar transcripciones desde la prueba.
class VozFalsa implements Voz {
  VozFalsa({this.hayDictado = true});

  final bool hayDictado;
  bool _escuchando = false;
  void Function(Transcripcion)? _alTranscribir;

  @override
  bool get escuchando => _escuchando;

  @override
  Future<bool> disponible() async => hayDictado;

  @override
  Future<void> escuchar({
    required void Function(Transcripcion) alTranscribir,
    required void Function(Object error) alFallar,
  }) async {
    if (!hayDictado) {
      alFallar(StateError('sin dictado'));
      return;
    }
    _escuchando = true;
    _alTranscribir = alTranscribir;
  }

  @override
  Future<void> detener() async => _escuchando = false;

  /// Simula lo que va entendiendo el reconocedor.
  void transcribir(String texto, {bool definitiva = false}) =>
      _alTranscribir?.call(
        Transcripcion(texto: texto, definitiva: definitiva),
      );
}
