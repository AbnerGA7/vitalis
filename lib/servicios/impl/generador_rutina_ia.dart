/// Generación de la rutina de ejercicio del día por IA. ADR-03, sección 4.5.
///
/// La persona pidió explícitamente que los ejercicios los proponga la IA
/// libremente (a diferencia del plan de comidas, donde solo se generan los
/// platos y la proteína sigue siendo por fórmula). Aun así, la respuesta se
/// valida con cuidado: campos vacíos, tipos equivocados o duraciones fuera de
/// rango se traducen en `null` y quien llama cae al catálogo de rutinas
/// vetadas por seguridad.
library;

import 'dart:convert';

import '../../dominio/modelos/enums.dart';
import '../../dominio/modelos/rutina.dart';
import '../contratos/contratos.dart';

String _instruccionGeneradorRutina() =>
    'Eres un generador de rutinas de ejercicio para una app peruana de '
    'fitness en casa, con poco espacio, sin salir de una silla o de pie en '
    'la sala. Devuelves solo JSON válido, sin explicaciones ni texto '
    'alrededor ni bloques de código. Responde en español de Perú.';

String _peticionRutina(Objetivo objetivo) =>
    'Genera una rutina de ejercicio en casa para el objetivo '
    '"${objetivo.etiqueta}". Entre 3 y 6 ejercicios de trabajo, alternando '
    'con descansos cortos entre cada uno. Responde solo con este JSON: '
    '{"nombre": "...", "duracionMin": N, "material": "...", '
    '"impacto": "bajo|medio|alto", "porque": "...", '
    '"notaAdaptacion": "...", "pasos": [{"tipo": "trabajo|descanso", '
    '"nombre": "...", "detalle": "...", "duracionS": N, '
    '"indicacion": "..."}, ...]}. duracionS entre 15 y 90.';

String _extraerJsonObjeto(String texto) {
  final inicio = texto.indexOf('{');
  final fin = texto.lastIndexOf('}');
  if (inicio == -1 || fin == -1 || fin < inicio) return texto;
  return texto.substring(inicio, fin + 1);
}

Paso? _parsearPaso(Object? crudo) {
  if (crudo is! Map) return null;
  final tipoTexto = crudo['tipo'];
  final nombre = crudo['nombre'];
  final detalle = crudo['detalle'];
  final duracionS = crudo['duracionS'];
  final indicacion = crudo['indicacion'];
  if (tipoTexto != 'trabajo' && tipoTexto != 'descanso') return null;
  if (nombre is! String || nombre.trim().isEmpty) return null;
  if (detalle is! String || detalle.trim().isEmpty) return null;
  if (duracionS is! num || duracionS < 5 || duracionS > 120) return null;
  if (indicacion is! String || indicacion.trim().isEmpty) return null;
  return Paso(
    tipo: tipoTexto == 'trabajo' ? TipoPaso.trabajo : TipoPaso.descanso,
    nombre: nombre.trim(),
    detalle: detalle.trim(),
    duracionS: duracionS.round(),
    indicacion: indicacion.trim(),
  );
}

Rutina? _parsearRutinaGenerada(String? crudo, String id) {
  if (crudo == null) return null;
  try {
    final mapa = jsonDecode(_extraerJsonObjeto(crudo));
    if (mapa is! Map) return null;
    final nombre = mapa['nombre'];
    final duracionMin = mapa['duracionMin'];
    final material = mapa['material'];
    final impacto = mapa['impacto'];
    final porque = mapa['porque'];
    final notaAdaptacion = mapa['notaAdaptacion'];
    final pasosCrudo = mapa['pasos'];
    if (nombre is! String || nombre.trim().isEmpty) return null;
    if (duracionMin is! num || duracionMin <= 0) return null;
    if (material is! String || material.trim().isEmpty) return null;
    if (impacto is! String || impacto.trim().isEmpty) return null;
    if (porque is! String || porque.trim().isEmpty) return null;
    if (notaAdaptacion is! String || notaAdaptacion.trim().isEmpty) {
      return null;
    }
    if (pasosCrudo is! List || pasosCrudo.isEmpty) return null;

    final pasos = <Paso>[];
    for (final item in pasosCrudo) {
      final paso = _parsearPaso(item);
      if (paso == null) return null;
      pasos.add(paso);
    }
    if (!pasos.any((p) => p.esTrabajo)) return null;

    return Rutina(
      id: id,
      nombre: nombre.trim(),
      duracionMin: duracionMin.round(),
      material: material.trim(),
      impacto: impacto.trim(),
      porque: porque.trim(),
      notaAdaptacion: notaAdaptacion.trim(),
      pasos: pasos,
    );
  } on FormatException {
    return null;
  }
}

/// Genera la rutina del día con IA, o `null` si no fue posible (modelo no
/// disponible, respuesta inválida...).
Future<Rutina?> generarRutinaConIA({
  required GeneradorContenidoIA generador,
  required Objetivo objetivo,
  required String id,
}) async {
  final crudo = await generador.generar(
    instruccionSistema: _instruccionGeneradorRutina(),
    peticion: _peticionRutina(objetivo),
  );
  return _parsearRutinaGenerada(crudo, id);
}
