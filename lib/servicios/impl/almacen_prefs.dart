/// Almacén local sobre SharedPreferences. ADR-05 · RNF-01, RNF-09, RNF-10.
///
/// Todo vive en el espacio privado de la app: al desinstalar desaparece.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../dominio/modelos/perfil.dart';
import '../../dominio/modelos/plan_comidas.dart';
import '../../dominio/modelos/rutina.dart';
import '../contratos/contratos.dart';

/// Días de registro de agua que se conservan para el resumen y la exportación.
const int diasHistorialAgua = 60;

class AlmacenPrefs implements Almacen {
  AlmacenPrefs(this._prefs);

  static const _clavePerfil = 'vitalis.perfil';
  static const _clavePreferencias = 'vitalis.preferencias';
  static const _clavePlan = 'vitalis.plan';
  static const _claveAgua = 'vitalis.agua';
  static const _claveSesiones = 'vitalis.sesiones';
  static const _claveUrlModeloIA = 'vitalis.urlModeloIA';

  final SharedPreferences _prefs;

  static Future<AlmacenPrefs> abrir() async =>
      AlmacenPrefs(await SharedPreferences.getInstance());

  Map<String, Object?>? _leerMapa(String clave) {
    final texto = _prefs.getString(clave);
    if (texto == null || texto.isEmpty) return null;
    try {
      return (jsonDecode(texto) as Map).cast<String, Object?>();
    } on FormatException {
      // Dato corrupto: se descarta y la app arranca con valores iniciales.
      return null;
    }
  }

  @override
  Future<Perfil?> leerPerfil() async {
    final mapa = _leerMapa(_clavePerfil);
    return mapa == null ? null : Perfil.desdeJson(mapa);
  }

  @override
  Future<void> guardarPerfil(Perfil perfil) async {
    await _prefs.setString(_clavePerfil, jsonEncode(perfil.aJson()));
  }

  @override
  Future<Preferencias?> leerPreferencias() async {
    final mapa = _leerMapa(_clavePreferencias);
    return mapa == null ? null : Preferencias.desdeJson(mapa);
  }

  @override
  Future<void> guardarPreferencias(Preferencias preferencias) async {
    await _prefs.setString(
      _clavePreferencias,
      jsonEncode(preferencias.aJson()),
    );
  }

  @override
  Future<PlanComidas?> leerPlan() async {
    final mapa = _leerMapa(_clavePlan);
    return mapa == null ? null : PlanComidas.desdeJson(mapa);
  }

  @override
  Future<void> guardarPlan(PlanComidas plan) async {
    await _prefs.setString(_clavePlan, jsonEncode(plan.aJson()));
  }

  Map<String, int> _mapaAgua() {
    final texto = _prefs.getString(_claveAgua);
    if (texto == null || texto.isEmpty) return {};
    try {
      return (jsonDecode(texto) as Map).map(
        (clave, valor) => MapEntry(clave as String, (valor as num).toInt()),
      );
    } on FormatException {
      return {};
    }
  }

  @override
  Future<int> leerAgua(DateTime dia) async => _mapaAgua()[claveDia(dia)] ?? 0;

  @override
  Future<void> guardarAgua(DateTime dia, int ml) async {
    final mapa = _mapaAgua()..[claveDia(dia)] = ml;
    // Poda el historial para que el almacén no crezca sin límite.
    if (mapa.length > diasHistorialAgua) {
      final claves = mapa.keys.toList()..sort();
      for (final vieja in claves.take(mapa.length - diasHistorialAgua)) {
        mapa.remove(vieja);
      }
    }
    await _prefs.setString(_claveAgua, jsonEncode(mapa));
  }

  @override
  Future<List<SesionEntreno>> leerSesiones() async {
    final texto = _prefs.getString(_claveSesiones);
    if (texto == null || texto.isEmpty) return [];
    try {
      return (jsonDecode(texto) as List<Object?>)
          .map((s) => SesionEntreno.desdeJson((s as Map).cast<String, Object?>()))
          .toList();
    } on FormatException {
      return [];
    }
  }

  @override
  Future<void> guardarSesion(SesionEntreno sesion) async {
    final sesiones = await leerSesiones();
    // Una sesión por rutina y día: la última sustituye a la anterior.
    sesiones.removeWhere(
      (s) =>
          s.rutinaId == sesion.rutinaId &&
          claveDia(s.fecha) == claveDia(sesion.fecha),
    );
    sesiones.add(sesion);
    await _prefs.setString(
      _claveSesiones,
      jsonEncode(sesiones.map((s) => s.aJson()).toList()),
    );
  }

  @override
  Future<String?> leerUrlModeloIA() async => _prefs.getString(_claveUrlModeloIA);

  @override
  Future<void> guardarUrlModeloIA(String? url) async {
    if (url == null) {
      await _prefs.remove(_claveUrlModeloIA);
    } else {
      await _prefs.setString(_claveUrlModeloIA, url);
    }
  }

  @override
  Future<String> exportar() async {
    final volcado = <String, Object?>{
      'aplicacion': 'Vitalis',
      'generado': DateTime.now().toIso8601String(),
      'aviso': 'Estos datos nunca han salido de tu dispositivo.',
      'perfil': _leerMapa(_clavePerfil),
      'preferencias': _leerMapa(_clavePreferencias),
      'planActivo': _leerMapa(_clavePlan),
      'agua': _mapaAgua(),
      'sesiones': (await leerSesiones()).map((s) => s.aJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(volcado);
  }

  @override
  Future<void> borrarTodo() async {
    for (final clave in [
      _clavePerfil,
      _clavePreferencias,
      _clavePlan,
      _claveAgua,
      _claveSesiones,
      _claveUrlModeloIA,
    ]) {
      await _prefs.remove(clave);
    }
  }
}

/// Clave de día en formato YYYY-MM-DD.
String claveDia(DateTime fecha) =>
    '${fecha.year.toString().padLeft(4, '0')}-'
    '${fecha.month.toString().padLeft(2, '0')}-'
    '${fecha.day.toString().padLeft(2, '0')}';
