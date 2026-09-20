// Sección 9: proteína por tasa, reparto 30/35/20/15 y kcal. RF-20, RF-22.
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis/dominio/logica/generador_plan.dart';
import 'package:vitalis/dominio/logica/proteina.dart';
import 'package:vitalis/dominio/modelos/enums.dart';
import 'package:vitalis/dominio/modelos/plan_comidas.dart';

void main() {
  group('proteinaObjetivoG', () {
    test('aplica la tasa de cada objetivo de la sección 4.2', () {
      expect(
        proteinaObjetivoG(pesoKg: 70, tasa: TasaProteina.mantener),
        84,
      );
      expect(proteinaObjetivoG(pesoKg: 70, tasa: TasaProteina.fuerza), 112);
      expect(
        proteinaObjetivoG(pesoKg: 70, tasa: TasaProteina.recomposicion),
        140,
      );
    });

    test('redondea al entero más cercano', () {
      expect(proteinaObjetivoG(pesoKg: 72.5, tasa: TasaProteina.fuerza), 116);
    });

    test('peso no plausible devuelve cero en vez de negativo', () {
      expect(proteinaObjetivoG(pesoKg: 0, tasa: TasaProteina.fuerza), 0);
    });
  });

  test('el objetivo declarado arrastra su tasa sugerida (Anexo A)', () {
    expect(Objetivo.perderPeso.tasaSugerida, TasaProteina.recomposicion);
    expect(Objetivo.ganarFuerza.tasaSugerida, TasaProteina.fuerza);
    expect(Objetivo.mantenerMovilidad.tasaSugerida, TasaProteina.mantener);
  });

  test('kcal = round(prot × 4 / 0,32 / 10) × 10', () {
    expect(kcalDesdeProteina(34), 430);
    expect(kcalDesdeProteina(39), 490);
  });

  group('generarPlan', () {
    final fecha = DateTime(2026, 9, 19);

    test('reparte 30/35/20/15 % del objetivo', () {
      final plan = generarPlanDelDia(
        pesoKg: 70,
        tasa: TasaProteina.fuerza,
        preferencia: PreferenciaDieta.mixta,
        fecha: fecha,
      );
      expect(plan.objetivoProteinaG, 112);
      expect(plan.comidas.map((c) => c.proteinaG).toList(), [34, 39, 22, 17]);
    });

    test('el total no se aleja más de 1 g del objetivo por redondeo', () {
      for (final peso in [52.0, 63.4, 70.0, 88.9, 101.2]) {
        for (final tasa in TasaProteina.values) {
          final plan = generarPlanDelDia(
            pesoKg: peso,
            tasa: tasa,
            preferencia: PreferenciaDieta.mixta,
            fecha: fecha,
          );
          final desvio =
              (plan.totalProteinaG - plan.objetivoProteinaG).abs();
          expect(desvio, lessThanOrEqualTo(1), reason: 'peso $peso, $tasa');
        }
      }
    });

    test('son siempre cuatro comidas a las horas de la sección 4.3', () {
      final plan = generarPlanDelDia(
        pesoKg: 70,
        tasa: TasaProteina.mantener,
        preferencia: PreferenciaDieta.vegetariana,
        fecha: fecha,
      );
      expect(plan.comidas, hasLength(4));
      expect(
        plan.comidas.map((c) => c.hora).toList(),
        ['08:00', '13:00', '16:30', '20:00'],
      );
    });

    test('la preferencia cambia los platos pero no el objetivo', () {
      final mixta = generarPlanDelDia(
        pesoKg: 70,
        tasa: TasaProteina.fuerza,
        preferencia: PreferenciaDieta.mixta,
        fecha: fecha,
      );
      final vegetariana = generarPlanDelDia(
        pesoKg: 70,
        tasa: TasaProteina.fuerza,
        preferencia: PreferenciaDieta.vegetariana,
        fecha: fecha,
      );
      expect(vegetariana.objetivoProteinaG, mixta.objetivoProteinaG);
      expect(
        vegetariana.comidas.map((c) => c.plato),
        isNot(equals(mixta.comidas.map((c) => c.plato))),
      );
    });

    test('regenerar con otra semilla puede cambiar los platos', () {
      final platos = <String>{};
      for (var semilla = 0; semilla < 8; semilla++) {
        final plan = generarPlanDelDia(
          pesoKg: 70,
          tasa: TasaProteina.fuerza,
          preferencia: PreferenciaDieta.mixta,
          fecha: fecha,
          semilla: semilla,
        );
        platos.add(plan.comidas.first.plato);
      }
      expect(platos.length, greaterThan(1));
    });

    test('el plan explica su porqué (RF-23)', () {
      final plan = generarPlanDelDia(
        pesoKg: 70,
        tasa: TasaProteina.fuerza,
        preferencia: PreferenciaDieta.mixta,
        fecha: fecha,
      );
      expect(plan.porque, contains('112'));
      expect(plan.porque, contains('orientación'));
    });

    test('el texto accesible sigue el formato de la sección 4.3', () {
      final plan = generarPlanDelDia(
        pesoKg: 70,
        tasa: TasaProteina.fuerza,
        preferencia: PreferenciaDieta.mixta,
        fecha: fecha,
      );
      final texto = plan.comidas.first.textoAccesible(1);
      expect(texto, startsWith('Comida 1 a las 08:00:'));
      expect(texto, contains('gramos de proteína'));
      expect(texto, contains('kilocalorías'));
    });

    test('ida y vuelta por JSON conserva el plan', () {
      final plan = generarPlanDelDia(
        pesoKg: 70,
        tasa: TasaProteina.fuerza,
        preferencia: PreferenciaDieta.sinLactosa,
        fecha: fecha,
      );
      final copia = PlanComidas.desdeJson(plan.aJson());
      expect(copia.objetivoProteinaG, plan.objetivoProteinaG);
      expect(copia.comidas.first.plato, plan.comidas.first.plato);
      expect(copia.preferencia, PreferenciaDieta.sinLactosa);
    });
  });
}
