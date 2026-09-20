// Sección 9: ida y vuelta por JSON de Rutina/Paso, necesaria para poder
// guardar una rutina generada por IA (sección 4.5, sección 8).
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis/dominio/modelos/enums.dart';
import 'package:vitalis/dominio/modelos/rutina.dart';

void main() {
  test('Rutina ida y vuelta por JSON conserva todos los campos', () {
    final rutina = Rutina(
      id: 'ia-2026-09-20',
      nombre: 'Piernas y core en silla',
      duracionMin: 14,
      material: 'Silla',
      impacto: 'bajo',
      porque: 'Trabaja piernas y abdomen sin salir de la silla.',
      notaAdaptacion: 'Todo se hace sentada.',
      pasos: const [
        Paso(
          tipo: TipoPaso.trabajo,
          nombre: 'Sentadilla en silla',
          detalle: 'Arriba y abajo despacio',
          duracionS: 30,
          indicacion: 'Empuja con los talones.',
        ),
        Paso(
          tipo: TipoPaso.descanso,
          nombre: 'Descanso',
          detalle: 'A continuación: Giro de tronco',
          duracionS: 15,
          indicacion: 'Respira hondo.',
        ),
      ],
    );

    final reconstruida =
        Rutina.desdeJson(rutina.aJson().cast<String, Object?>());

    expect(reconstruida.id, rutina.id);
    expect(reconstruida.nombre, rutina.nombre);
    expect(reconstruida.duracionMin, rutina.duracionMin);
    expect(reconstruida.material, rutina.material);
    expect(reconstruida.impacto, rutina.impacto);
    expect(reconstruida.porque, rutina.porque);
    expect(reconstruida.notaAdaptacion, rutina.notaAdaptacion);
    expect(reconstruida.pasos.length, rutina.pasos.length);
    for (var i = 0; i < rutina.pasos.length; i++) {
      expect(reconstruida.pasos[i].tipo, rutina.pasos[i].tipo);
      expect(reconstruida.pasos[i].nombre, rutina.pasos[i].nombre);
      expect(reconstruida.pasos[i].detalle, rutina.pasos[i].detalle);
      expect(reconstruida.pasos[i].duracionS, rutina.pasos[i].duracionS);
      expect(reconstruida.pasos[i].indicacion, rutina.pasos[i].indicacion);
    }
  });
}
