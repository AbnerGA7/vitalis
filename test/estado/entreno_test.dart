// Sección 9: el reproductor dispara las señales de cada canal y guarda la
// sesión. RF-43, RF-45, RF-60, RF-61 · RNF-06.
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis/dominio/catalogo/rutinas.dart';
import 'package:vitalis/dominio/modelos/enums.dart';
import 'package:vitalis/dominio/modelos/perfil.dart';
import 'package:vitalis/estado/estado_entreno.dart';

import '../dobles/entorno.dart';

void main() {
  /// Preferencias con una necesidad concreta marcada.
  Preferencias con(Necesidad necesidad) => Preferencias.inicial()
      .copiarCon(onboardingCompletado: true)
      .alternarNecesidad(necesidad);

  test('empezar deja el reproductor en el primer paso', () {
    final entorno = Entorno();
    final contenedor = entorno.contenedor();
    contenedor.read(entrenoProvider.notifier).empezar(fuerzaSentada);

    final estado = contenedor.read(entrenoProvider);
    expect(estado.activo, isTrue);
    expect(estado.cronometro!.numeroPaso, 1);
    expect(estado.cronometro!.paso.nombre, 'Sentadilla en silla');
  });

  test('RF-61: con baja visión declarada, la fase empieza vibrando', () {
    final entorno = Entorno(preferencias: con(Necesidad.bajaVision));
    final contenedor = entorno.contenedor();
    contenedor.read(entrenoProvider.notifier).empezar(fuerzaSentada);

    expect(entorno.haptico.patrones, contains('inicio'));
  });

  test('sin necesidades declaradas, empezar no vibra por sorpresa', () {
    final entorno = Entorno();
    final contenedor = entorno.contenedor();
    contenedor.read(entrenoProvider.notifier).empezar(fuerzaSentada);

    expect(entorno.haptico.patrones, isEmpty);
  });

  test('anuncia el ejercicio antes de empezar (RF-61)', () {
    final entorno = Entorno();
    final contenedor = entorno.contenedor();
    contenedor.read(entrenoProvider.notifier).empezar(fuerzaSentada);

    expect(
      entorno.anunciador.mensajes.first,
      contains('Sentadilla en silla'),
    );
  });

  test('pausar congela el restante y reanudar no pierde lo corrido', () {
    final entorno = Entorno();
    final contenedor = entorno.contenedor();
    final notificador = contenedor.read(entrenoProvider.notifier);
    notificador.empezar(fuerzaSentada);

    entorno.reloj.avanzar(const Duration(seconds: 10));
    notificador.pausar();
    final cronometro = contenedor.read(entrenoProvider).cronometro!;
    expect(cronometro.restanteS(entorno.reloj.ahora()), 20);

    entorno.reloj.avanzar(const Duration(minutes: 5));
    expect(cronometro.restanteS(entorno.reloj.ahora()), 20);

    notificador.reanudar();
    final reanudado = contenedor.read(entrenoProvider).cronometro!;
    expect(reanudado.restanteS(entorno.reloj.ahora()), 20);
  });

  test('saltar al paso siguiente reinicia su duración', () {
    final entorno = Entorno();
    final contenedor = entorno.contenedor();
    final notificador = contenedor.read(entrenoProvider.notifier);
    notificador.empezar(fuerzaSentada);

    entorno.reloj.avanzar(const Duration(seconds: 20));
    notificador.siguiente();

    final cronometro = contenedor.read(entrenoProvider).cronometro!;
    expect(cronometro.numeroPaso, 2);
    expect(cronometro.paso.tipo, TipoPaso.descanso);
    expect(cronometro.restanteS(entorno.reloj.ahora()), 15);
  });

  test('salir guarda la sesión y cierra la capa', () async {
    final entorno = Entorno();
    final contenedor = entorno.contenedor();
    final notificador = contenedor.read(entrenoProvider.notifier);

    notificador.empezar(fuerzaSentada);
    await notificador.salir();

    expect(contenedor.read(entrenoProvider).activo, isFalse);
    expect(entorno.almacen.sesiones, hasLength(1));
    expect(entorno.almacen.sesiones.first.rutinaId, idFuerzaSentada);
  });

  test('la fase avanza sola al vencer y vibra al terminar', () {
    fakeAsync((async) {
      final entorno = Entorno(
        ahora: DateTime(2026, 9, 19, 9),
        preferencias: con(Necesidad.bajaVision),
      );
      final contenedor = entorno.contenedor();
      contenedor.read(entrenoProvider.notifier).empezar(fuerzaSentada);

      // El reloj falso avanza a la par que el temporizador de refresco.
      for (var i = 0; i < 160; i++) {
        entorno.reloj.avanzar(periodoRefresco);
        async.elapse(periodoRefresco);
      }

      final estado = contenedor.read(entrenoProvider);
      expect(estado.cronometro!.numeroPaso, greaterThan(1));
      expect(entorno.haptico.patrones, contains('fin'));
      expect(entorno.haptico.patrones, contains('t3'));
    });
  });

  test('con perfil sordo, el fin de descanso enciende el destello', () {
    fakeAsync((async) {
      final entorno = Entorno(
        ahora: DateTime(2026, 9, 19, 9),
        preferencias: con(Necesidad.hipoacusia),
      );
      final contenedor = entorno.contenedor();
      final notificador = contenedor.read(entrenoProvider.notifier);
      notificador.empezar(fuerzaSentada);

      // Saltamos al descanso y dejamos que venza.
      notificador.siguiente();
      expect(
        contenedor.read(entrenoProvider).cronometro!.paso.tipo,
        TipoPaso.descanso,
      );

      for (var i = 0; i < 80; i++) {
        entorno.reloj.avanzar(periodoRefresco);
        async.elapse(periodoRefresco);
      }

      expect(contenedor.read(entrenoProvider).destellando, isTrue);
    });
  });

  test('saltar de paso cancela el destello', () {
    fakeAsync((async) {
      final entorno = Entorno(
        ahora: DateTime(2026, 9, 19, 9),
        preferencias: con(Necesidad.hipoacusia),
      );
      final contenedor = entorno.contenedor();
      final notificador = contenedor.read(entrenoProvider.notifier);
      notificador.empezar(fuerzaSentada);
      notificador.siguiente();

      for (var i = 0; i < 80; i++) {
        entorno.reloj.avanzar(periodoRefresco);
        async.elapse(periodoRefresco);
      }
      expect(contenedor.read(entrenoProvider).destellando, isTrue);

      notificador.siguiente();
      expect(contenedor.read(entrenoProvider).destellando, isFalse);
    });
  });

  test('RF-45: el fin de descanso avisa aunque no haya nada declarado', () {
    fakeAsync((async) {
      // Perfil estándar: ninguna necesidad marcada.
      final entorno = Entorno(ahora: DateTime(2026, 9, 19, 9));
      final contenedor = entorno.contenedor();
      final notificador = contenedor.read(entrenoProvider.notifier);
      notificador.empezar(fuerzaSentada);
      entorno.haptico.patrones.clear();

      notificador.siguiente();
      expect(
        contenedor.read(entrenoProvider).cronometro!.paso.tipo,
        TipoPaso.descanso,
      );

      for (var i = 0; i < 80; i++) {
        entorno.reloj.avanzar(periodoRefresco);
        async.elapse(periodoRefresco);
      }

      // Ha terminado el descanso y ha habido señal no sonora.
      expect(
        contenedor.read(entrenoProvider).cronometro!.paso.tipo,
        TipoPaso.trabajo,
      );
      expect(entorno.haptico.patrones, contains('fin'));
    });
  });
}
