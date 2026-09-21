// Perfil, preferencias y acumulación de necesidades. RF-50, RF-62, sección 5.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis/dominio/modelos/enums.dart';
import 'package:vitalis/dominio/modelos/perfil.dart';

void main() {
  test('cambiar de objetivo arrastra su tasa sugerida', () {
    final perfil = Perfil.inicial().conObjetivo(Objetivo.ganarFuerza);
    expect(perfil.objetivo, Objetivo.ganarFuerza);
    expect(perfil.tasaProteina, TasaProteina.fuerza);
  });

  test('la tasa puede ajustarse a mano sin tocar el objetivo', () {
    final perfil = Perfil.inicial()
        .conObjetivo(Objetivo.ganarFuerza)
        .copiarCon(tasaProteina: TasaProteina.recomposicion);
    expect(perfil.objetivo, Objetivo.ganarFuerza);
    expect(perfil.tasaProteina, TasaProteina.recomposicion);
  });

  test('peso y altura se acotan a rangos plausibles', () {
    expect(acotarPeso(5), pesoMinimoKg);
    expect(acotarPeso(900), pesoMaximoKg);
    expect(acotarAltura(10), alturaMinimaCm);
    expect(acotarAltura(400), alturaMaximaCm);
    expect(acotarPeso(70), 70);
  });

  test('las necesidades se acumulan y se alternan', () {
    var prefs = Preferencias.inicial();
    expect(prefs.necesidades, isEmpty);

    prefs = prefs.alternarNecesidad(Necesidad.hipoacusia);
    prefs = prefs.alternarNecesidad(Necesidad.bajaVision);
    expect(prefs.necesidades, hasLength(2));
    expect(prefs.subtitulos, isTrue);
    expect(prefs.vibracion, isTrue);

    prefs = prefs.alternarNecesidad(Necesidad.hipoacusia);
    expect(prefs.subtitulos, isFalse);
    expect(prefs.vibracion, isTrue);
  });

  test('el tema oscuro es el de partida (RNF-03, RNF-07)', () {
    expect(Preferencias.inicial().tema, TemaApp.oscuro);
    expect(Preferencias.inicial().unidades, Unidades.metrico);
    expect(Preferencias.inicial().onboardingCompletado, isFalse);
  });

  test('ida y vuelta por JSON conserva perfil y preferencias', () {
    final perfil = Perfil.inicial().conObjetivo(Objetivo.perderPeso);
    expect(Perfil.desdeJson(perfil.aJson()).tasaProteina,
        TasaProteina.recomposicion);

    final prefs = Preferencias.inicial()
        .alternarNecesidad(Necesidad.bajaVision)
        .copiarCon(tema: TemaApp.claro, onboardingCompletado: true);
    final copia = Preferencias.desdeJson(prefs.aJson());
    expect(copia.necesidades, {Necesidad.bajaVision});
    expect(copia.tema, TemaApp.claro);
    expect(copia.onboardingCompletado, isTrue);
  });

  test('gustos y exclusiones sobreviven al guardado real (jsonEncode/Decode)',
      () {
    final perfil = Perfil.inicial().copiarCon(
      comidasFavoritas: const ['pollo', 'palta'],
      ingredientesEvitar: const ['tomate', 'cebolla'],
    );

    // almacen_prefs.dart guarda con jsonEncode y lee con jsonDecode, no solo
    // con el mapa en memoria: sin pasar por ahí no se detectaría un cast que
    // solo falla con la List<dynamic> real que produce jsonDecode.
    final decodificado =
        jsonDecode(jsonEncode(perfil.aJson())) as Map<String, Object?>;
    final copia = Perfil.desdeJson(decodificado);

    expect(copia.comidasFavoritas, ['pollo', 'palta']);
    expect(copia.ingredientesEvitar, ['tomate', 'cebolla']);
  });

  test('un perfil guardado antes de este campo no rompe la lectura', () {
    final json = Perfil.inicial().aJson()
      ..remove('comidasFavoritas')
      ..remove('ingredientesEvitar');
    final perfil = Perfil.desdeJson(json);
    expect(perfil.comidasFavoritas, isEmpty);
    expect(perfil.ingredientesEvitar, isEmpty);
  });
}
