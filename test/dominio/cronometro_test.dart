// Sección 9: cronómetro con reloj simulado (pausa, salto, fin). RNF-06, RF-43.
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis/dominio/catalogo/rutinas.dart';
import 'package:vitalis/dominio/logica/cronometro.dart';
import 'package:vitalis/dominio/modelos/enums.dart';
import 'package:vitalis/dominio/modelos/rutina.dart';

final Rutina _rutinaPrueba = Rutina(
  id: 'prueba',
  nombre: 'Rutina de prueba',
  duracionMin: 2,
  material: 'Silla',
  impacto: 'bajo',
  porque: 'Sirve para probar el cronómetro.',
  notaAdaptacion: 'Sin adaptación.',
  pasos: const [
    Paso(
      tipo: TipoPaso.trabajo,
      nombre: 'Sentadilla en silla',
      detalle: 'Arriba y abajo',
      duracionS: 30,
      indicacion: 'Empuja con los talones.',
    ),
    Paso(
      tipo: TipoPaso.descanso,
      nombre: 'Descanso',
      detalle: 'A continuación: Remo con banda',
      duracionS: 15,
      indicacion: 'Respira.',
    ),
    Paso(
      tipo: TipoPaso.trabajo,
      nombre: 'Remo con banda',
      detalle: 'Codos atrás',
      duracionS: 40,
      indicacion: 'Junta los omóplatos.',
    ),
  ],
);

void main() {
  final t0 = DateTime(2026, 9, 19, 10);

  test('arranca en el primer paso con la duración completa', () {
    final estado = EstadoCronometro.iniciar(_rutinaPrueba, t0);
    expect(estado.numeroPaso, 1);
    expect(estado.totalPasos, 3);
    expect(estado.restanteS(t0), 30);
    expect(estado.terminado, isFalse);
  });

  test('el restante se calcula por reloj real, no por ticks', () {
    final estado = EstadoCronometro.iniciar(_rutinaPrueba, t0);
    // Simula que el proceso estuvo suspendido 12 s: no hubo ningún tick.
    expect(estado.restanteS(t0.add(const Duration(seconds: 12))), 18);
    expect(estado.restanteS(t0.add(const Duration(seconds: 30))), 0);
    expect(estado.restanteS(t0.add(const Duration(seconds: 45))), 0);
  });

  test('la pausa congela el restante por mucho que pase el reloj', () {
    final estado = EstadoCronometro.iniciar(_rutinaPrueba, t0)
        .pausar(t0.add(const Duration(seconds: 10)));
    expect(estado.enPausa, isTrue);
    expect(estado.restanteS(t0.add(const Duration(seconds: 10))), 20);
    expect(estado.restanteS(t0.add(const Duration(minutes: 5))), 20);
  });

  test('reanudar no pierde el tiempo ya corrido', () {
    final estado = EstadoCronometro.iniciar(_rutinaPrueba, t0)
        .pausar(t0.add(const Duration(seconds: 10)))
        .reanudar(t0.add(const Duration(minutes: 5)));
    expect(estado.enPausa, isFalse);
    expect(estado.restanteS(t0.add(const Duration(minutes: 5))), 20);
    expect(
      estado.restanteS(t0.add(const Duration(minutes: 5, seconds: 20))),
      0,
    );
  });

  test('al llegar a cero avanza solo al paso siguiente', () {
    final estado = EstadoCronometro.iniciar(_rutinaPrueba, t0);
    final t30 = t0.add(const Duration(seconds: 30));
    final avanzado = estado.avanzarSiVencio(t30);
    expect(avanzado.numeroPaso, 2);
    expect(avanzado.paso.tipo, TipoPaso.descanso);
    expect(avanzado.restanteS(t30), 15);
  });

  test('no avanza si la fase no ha vencido ni si está en pausa', () {
    final estado = EstadoCronometro.iniciar(_rutinaPrueba, t0);
    final t10 = t0.add(const Duration(seconds: 10));
    expect(estado.avanzarSiVencio(t10).numeroPaso, 1);

    final pausado = estado.pausar(t10);
    final t100 = t0.add(const Duration(seconds: 100));
    expect(pausado.avanzarSiVencio(t100).numeroPaso, 1);
  });

  test('saltar reinicia la duración del paso destino', () {
    final t20 = t0.add(const Duration(seconds: 20));
    final estado = EstadoCronometro.iniciar(_rutinaPrueba, t0).siguiente(t20);
    expect(estado.numeroPaso, 2);
    expect(estado.restanteS(t20), 15);
  });

  test('el paso anterior también reinicia su duración', () {
    final t20 = t0.add(const Duration(seconds: 20));
    final estado = EstadoCronometro.iniciar(_rutinaPrueba, t0)
        .siguiente(t20)
        .anterior(t20);
    expect(estado.numeroPaso, 1);
    expect(estado.restanteS(t20), 30);
  });

  test('en el primer paso, anterior solo lo reinicia', () {
    final t20 = t0.add(const Duration(seconds: 20));
    final estado = EstadoCronometro.iniciar(_rutinaPrueba, t0).anterior(t20);
    expect(estado.numeroPaso, 1);
    expect(estado.restanteS(t20), 30);
  });

  test('tras el último paso la rutina termina', () {
    var estado = EstadoCronometro.iniciar(_rutinaPrueba, t0);
    estado = estado.siguiente(t0).siguiente(t0);
    expect(estado.numeroPaso, 3);
    expect(estado.terminado, isFalse);
    estado = estado.siguiente(t0);
    expect(estado.terminado, isTrue);
  });

  test('T-3 solo se cumple a falta de tres segundos y sin pausa', () {
    final estado = EstadoCronometro.iniciar(_rutinaPrueba, t0);
    expect(estado.esT3(t0.add(const Duration(seconds: 26))), isFalse);
    expect(estado.esT3(t0.add(const Duration(seconds: 27))), isTrue);
    expect(estado.esT3(t0.add(const Duration(seconds: 28))), isFalse);

    final pausado = estado.pausar(t0.add(const Duration(seconds: 27)));
    expect(pausado.esT3(t0.add(const Duration(seconds: 27))), isFalse);
  });

  test('la rutina real de fuerza sentada tiene 5 ejercicios', () {
    expect(fuerzaSentada.numeroEjercicios, 5);
    expect(fuerzaSentada.pasos.first.nombre, 'Sentadilla en silla');
    expect(fuerzaSentada.pasos.first.duracionS, 30);
  });

  test('formatearCuentaAtras muestra segundos sueltos y minutos', () {
    expect(formatearCuentaAtras(9), '9');
    expect(formatearCuentaAtras(59), '59');
    expect(formatearCuentaAtras(60), '1:00');
    expect(formatearCuentaAtras(75), '1:15');
  });
}
