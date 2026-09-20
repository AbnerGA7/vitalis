// Sección 9 · nivel «Estado»: cambiar el peso recalcula proteína, plan y
// respuesta del asistente; los perfiles de accesibilidad se acumulan.
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis/dominio/logica/hidratacion.dart';
import 'package:vitalis/dominio/modelos/enums.dart';
import 'package:vitalis/dominio/modelos/perfil.dart';
import 'package:vitalis/estado/notificador_app.dart';

import '../dobles/entorno.dart';

void main() {
  test('cambiar el peso recalcula la proteína objetivo', () async {
    final entorno = Entorno(
      perfil: Perfil.inicial().conObjetivo(Objetivo.ganarFuerza),
    );
    final contenedor = entorno.contenedor();
    final notificador = contenedor.read(estadoAppProvider.notifier);

    expect(contenedor.read(estadoAppProvider).proteinaObjetivo, 112);

    await notificador.cambiarPeso(80);
    expect(contenedor.read(estadoAppProvider).proteinaObjetivo, 128);
    expect(entorno.almacen.perfil?.pesoKg, 80);
  });

  test('cambiar el peso invalida el plan vigente', () async {
    final entorno = Entorno();
    final contenedor = entorno.contenedor();
    final notificador = contenedor.read(estadoAppProvider.notifier);

    await notificador.generarPlan();
    expect(contenedor.read(estadoAppProvider).planVigente, isTrue);

    await notificador.cambiarPeso(95);
    expect(contenedor.read(estadoAppProvider).planVigente, isFalse);
    expect(contenedor.read(estadoAppProvider).planUsadoHoy, isFalse);
  });

  test('cambiar la preferencia también invalida el plan', () async {
    final entorno = Entorno();
    final contenedor = entorno.contenedor();
    final notificador = contenedor.read(estadoAppProvider.notifier);

    await notificador.generarPlan();
    await notificador.cambiarPreferenciaDieta(PreferenciaDieta.vegetariana);
    expect(contenedor.read(estadoAppProvider).planVigente, isFalse);
  });

  test('el objetivo arrastra la tasa y se puede ajustar después', () async {
    final entorno = Entorno();
    final contenedor = entorno.contenedor();
    final notificador = contenedor.read(estadoAppProvider.notifier);

    await notificador.cambiarObjetivo(Objetivo.perderPeso);
    expect(
      contenedor.read(estadoAppProvider).perfil.tasaProteina,
      TasaProteina.recomposicion,
    );

    await notificador.cambiarTasa(TasaProteina.mantener);
    final estado = contenedor.read(estadoAppProvider);
    expect(estado.perfil.objetivo, Objetivo.perderPeso);
    expect(estado.perfil.tasaProteina, TasaProteina.mantener);
  });

  test('las necesidades se acumulan y se persisten', () async {
    final entorno = Entorno();
    final contenedor = entorno.contenedor();
    final notificador = contenedor.read(estadoAppProvider.notifier);

    await notificador.alternarNecesidad(Necesidad.hipoacusia);
    await notificador.alternarNecesidad(Necesidad.bajaVision);

    final prefs = contenedor.read(estadoAppProvider).preferencias;
    expect(prefs.subtitulos, isTrue);
    expect(prefs.vibracion, isTrue);
    expect(entorno.almacen.preferencias?.necesidades, hasLength(2));
  });

  test('el agua respeta el tope diario y se guarda', () async {
    final entorno = Entorno(aguaMl: 2800);
    final contenedor = entorno.contenedor();
    final notificador = contenedor.read(estadoAppProvider.notifier);

    await notificador.registrarAgua(500);
    expect(contenedor.read(estadoAppProvider).aguaMl, topeDiarioMl);

    await notificador.registrarAgua(250);
    expect(contenedor.read(estadoAppProvider).aguaMl, topeDiarioMl);
  });

  test('al cambiar de día se reinician agua y plan', () async {
    final entorno = Entorno(aguaMl: 1000);
    final contenedor = entorno.contenedor();
    final notificador = contenedor.read(estadoAppProvider.notifier);

    await notificador.generarPlan();
    expect(contenedor.read(estadoAppProvider).plan, isNotNull);

    entorno.reloj.avanzar(const Duration(days: 1));
    final cambio = await notificador.comprobarCambioDeDia();

    expect(cambio, isTrue);
    final estado = contenedor.read(estadoAppProvider);
    expect(estado.aguaMl, 0);
    expect(estado.plan, isNull);
  });

  test('el mismo día no reinicia nada', () async {
    final entorno = Entorno(aguaMl: 1000);
    final contenedor = entorno.contenedor();
    final notificador = contenedor.read(estadoAppProvider.notifier);

    entorno.reloj.avanzar(const Duration(hours: 6));
    expect(await notificador.comprobarCambioDeDia(), isFalse);
    expect(contenedor.read(estadoAppProvider).aguaMl, 1000);
  });

  test('borrar mis datos deja la app como recién instalada', () async {
    final entorno = Entorno();
    final contenedor = entorno.contenedor();
    final notificador = contenedor.read(estadoAppProvider.notifier);

    await notificador.cambiarPeso(88);
    await notificador.generarPlan();
    await notificador.borrarDatos();

    final estado = contenedor.read(estadoAppProvider);
    expect(estado.perfil.pesoKg, Perfil.inicial().pesoKg);
    expect(estado.plan, isNull);
    expect(estado.preferencias.onboardingCompletado, isFalse);
    expect(entorno.almacen.perfil, isNull);
  });
}
