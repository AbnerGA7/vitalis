/// Reglas de hidratación. Sección 4.4 · RF-30, RF-31.
library;

/// Meta diaria (supuesto pendiente de validar, Anexo A).
const int metaDiariaMl = 2500;

/// Tope de registro diario: por encima no se acumula.
const int topeDiarioMl = 3000;

/// Un vaso son 250 ml.
const int vasoMl = 250;

/// Suma un registro respetando el tope de 3.000 ml/día.
int registrarAgua({required int actualMl, required int incrementoMl}) {
  final suma = actualMl + incrementoMl;
  if (suma < 0) return 0;
  return suma > topeDiarioMl ? topeDiarioMl : suma;
}

/// Progreso hacia la meta, acotado a 1.
double progresoAgua(int ml) {
  if (ml <= 0) return 0;
  final progreso = ml / metaDiariaMl;
  return progreso > 1 ? 1 : progreso;
}

/// Vasos de 250 ml que faltan para la meta.
int vasosRestantes(int ml) {
  final faltan = metaDiariaMl - ml;
  if (faltan <= 0) return 0;
  return (faltan / vasoMl).ceil();
}

/// Frase de estado de la sección 4.4 («5 vasos más»).
String fraseHidratacion(int ml) {
  final restantes = vasosRestantes(ml);
  if (restantes == 0) return 'Meta del día cumplida. Bien hecho.';
  if (restantes == 1) return 'Te queda 1 vaso para la meta del día.';
  return 'Te quedan $restantes vasos para la meta del día.';
}
