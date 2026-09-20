/// Clasificador de intenciones del asistente. Sección 4.6 · RF-12.
///
/// Reglas puras por palabras clave, sin distinguir mayúsculas ni acentos.
/// No inventa: lo que no reconoce pide precisión con tres ejemplos.
library;

import '../modelos/enums.dart';

const Map<Intencion, List<String>> _palabrasClave = {
  Intencion.plan: ['proteina', 'comida', 'comidas', 'dieta', 'plan', 'comer'],
  Intencion.agua: ['agua', 'hidratacion', 'beber', 'vaso', 'vasos', 'bebi'],
  Intencion.entreno: [
    'entreno',
    'entrenamiento',
    'rutina',
    'ejercicio',
    'ejercicios',
    'entrenar',
  ],
};

/// Verbos que delatan una petición explícita («dame mi plan»), a diferencia
/// de una frase informativa («hoy comí pollo con arroz»). Se exigen para el
/// grupo `plan`, el más propenso a aparecer en charla libre sobre comida: sin
/// esto, contarle al asistente lo que has comido disparaba siempre la misma
/// plantilla fija en vez de dejar que la conversación libre lo entendiera.
const List<String> _verbosPeticion = [
  'dame',
  'apunta',
  'anota',
  'registra',
  'dime',
  'cuanto',
  'cuanta',
  'necesito',
  'quiero',
  'generame',
  'hazme',
  'muestrame',
  'pon',
  'empieza',
  'comienza',
  'toca',
];

/// Quita acentos y pasa a minúsculas para que «proteína» y «proteina» coincidan.
String normalizar(String texto) {
  const con = 'áàäâéèëêíìïîóòöôúùüûñçÁÀÄÂÉÈËÊÍÌÏÎÓÒÖÔÚÙÜÛÑÇ';
  const sin = 'aaaaeeeeiiiioooouuuuncAAAAEEEEIIIIOOOOUUUUNC';
  final buffer = StringBuffer();
  for (final rune in texto.runes) {
    final caracter = String.fromCharCode(rune);
    final indice = con.indexOf(caracter);
    buffer.write(indice >= 0 ? sin[indice] : caracter);
  }
  return buffer.toString().toLowerCase();
}

/// Clasifica el texto de la persona en una de las intenciones de la sección 4.6.
///
/// Si varias intenciones coinciden gana la que aparece antes en el texto, para
/// que «quiero agua antes del entreno» se lea como agua.
Intencion clasificarIntencion(String texto) {
  final normalizado = normalizar(texto);
  if (normalizado.trim().isEmpty) return Intencion.desconocida;

  var mejor = Intencion.desconocida;
  var mejorPosicion = 1 << 30;

  for (final entrada in _palabrasClave.entries) {
    for (final palabra in entrada.value) {
      final posicion = normalizado.indexOf(palabra);
      if (posicion >= 0 && posicion < mejorPosicion) {
        mejorPosicion = posicion;
        mejor = entrada.key;
      }
    }
  }

  if (mejor == Intencion.plan) {
    // Una sola palabra («proteína», «dieta») es una consulta directa, no una
    // frase informativa: no hace falta verbo. A partir de dos palabras, sí.
    final unaSolaPalabra =
        normalizado.trim().split(RegExp(r'\s+')).length <= 1;
    final tienePeticion = _verbosPeticion.any(normalizado.contains);
    if (!unaSolaPalabra && !tienePeticion) return Intencion.desconocida;
  }
  return mejor;
}

/// Los tres ejemplos con los que el asistente pide precisión (RF-12).
const List<String> ejemplosSugeridos = [
  'Dame mi plan de comidas de hoy',
  'Apunta un vaso de agua',
  'Empieza el entrenamiento de hoy',
];

/// Respuesta cuando no se reconoce la intención. No inventa una respuesta.
const String textoNoEntendido =
    'No he sabido interpretar eso y prefiero no inventarme una respuesta. '
    'Puedo ayudarte con tu plan de comidas, con el agua del día o con tu '
    'entrenamiento. Por ejemplo:';

/// Sugerencias visibles con la conversación vacía (RF-14).
const List<String> sugerenciasInicio = [
  '¿Cuánta proteína necesito hoy?',
  'Apunta 250 ml de agua',
  '¿Qué entreno toca hoy?',
];
