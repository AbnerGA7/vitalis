/// Catálogo de rutinas. Sección 3 (Entreno) · RF-40, RF-41.
///
/// Cada rutina explica su «por qué». Las adaptaciones cambian la presentación,
/// nunca qué rutinas están disponibles (sección 4.7).
library;

import '../modelos/enums.dart';
import '../modelos/perfil.dart';
import '../modelos/rutina.dart';

Paso _trabajo(String nombre, String detalle, int segundos, String indicacion) =>
    Paso(
      tipo: TipoPaso.trabajo,
      nombre: nombre,
      detalle: detalle,
      duracionS: segundos,
      indicacion: indicacion,
    );

Paso _descanso(int segundos, String siguiente) => Paso(
      tipo: TipoPaso.descanso,
      nombre: 'Descanso',
      detalle: 'A continuación: $siguiente',
      duracionS: segundos,
      indicacion: 'Respira hondo y suelta los hombros.',
    );

/// Rutina de referencia del prototipo: «Fuerza sentada · 18 min».
const String idFuerzaSentada = 'fuerza-sentada';

final Rutina fuerzaSentada = Rutina(
  id: idFuerzaSentada,
  nombre: 'Fuerza sentada',
  duracionMin: 18,
  material: 'Silla y banda elástica',
  impacto: 'bajo',
  porque: 'Trabaja las piernas, la espalda y el pecho sin salir de la silla, '
      'así que el esfuerzo va al músculo y no al equilibrio.',
  notaAdaptacion: 'Todos los ejercicios se hacen sentada o apoyada en la '
      'pared. Si necesitas más tiempo entre series, la pausa espera por ti.',
  pasos: [
    _trabajo(
      'Sentadilla en silla',
      'Levántate y siéntate despacio, sin impulso',
      30,
      'Apoya los pies a la anchura de las caderas y sube empujando con los '
          'talones.',
    ),
    _descanso(15, 'Remo con banda'),
    _trabajo(
      'Remo con banda',
      'Tira de la banda llevando los codos atrás',
      40,
      'Junta los omóplatos al final de cada tirón y vuelve sin soltar de golpe.',
    ),
    _descanso(20, 'Flexión en pared'),
    _trabajo(
      'Flexión en pared',
      'Manos a la altura del pecho, cuerpo recto',
      30,
      'Cuanto más lejos pongas los pies, más cuesta. Baja contando hasta dos.',
    ),
    _descanso(20, 'Press de hombro con banda'),
    _trabajo(
      'Press de hombro con banda',
      'Empuja la banda hacia arriba desde los hombros',
      40,
      'No arquees la espalda: mete un poco el abdomen antes de empujar.',
    ),
    _descanso(20, 'Elevación de talones'),
    _trabajo(
      'Elevación de talones',
      'Sube los talones sentada, apoyando las manos',
      30,
      'Aguanta arriba un segundo antes de bajar.',
    ),
  ],
);

final Rutina movilidadHombro = Rutina(
  id: 'movilidad-hombro',
  nombre: 'Movilidad de hombro',
  duracionMin: 9,
  material: 'Sin material',
  impacto: 'muy bajo',
  porque: 'Desbloquea el hombro antes de cualquier empuje y alivia la tensión '
      'de estar muchas horas sentada.',
  notaAdaptacion:
      'Se hace de pie o sentada, sin cargar peso en ningún momento.',
  pasos: [
    _trabajo(
      'Círculos de hombro',
      'Círculos lentos hacia atrás',
      40,
      'Haz el círculo tan grande como puedas sin dolor.',
    ),
    _descanso(15, 'Apertura de pecho'),
    _trabajo(
      'Apertura de pecho',
      'Abre los brazos en cruz y aguanta',
      40,
      'Lleva el pecho adelante sin sacar las costillas.',
    ),
    _descanso(15, 'Deslizamiento en pared'),
    _trabajo(
      'Deslizamiento en pared',
      'Sube y baja los brazos pegados a la pared',
      45,
      'Si las muñecas se separan de la pared, baja el recorrido.',
    ),
  ],
);

final Rutina coreEnSilla = Rutina(
  id: 'core-en-silla',
  nombre: 'Core en silla',
  duracionMin: 12,
  material: 'Silla',
  impacto: 'bajo',
  porque: 'Un abdomen fuerte sostiene la espalda al levantarte, y se puede '
      'entrenar sin bajar al suelo.',
  notaAdaptacion: 'Ningún ejercicio pide tumbarse ni levantarse de la silla.',
  pasos: [
    _trabajo(
      'Marcha sentada',
      'Sube las rodillas alternando, sin prisa',
      40,
      'Mantén la espalda separada del respaldo.',
    ),
    _descanso(20, 'Giro de tronco'),
    _trabajo(
      'Giro de tronco',
      'Gira el tronco a un lado y al otro',
      40,
      'Gira desde las costillas, no desde los brazos.',
    ),
    _descanso(20, 'Extensión de pierna'),
    _trabajo(
      'Extensión de pierna',
      'Estira una pierna y aguanta arriba',
      40,
      'Aprieta el muslo arriba y cambia de pierna a mitad del tiempo.',
    ),
  ],
);

final Rutina cardioBajoImpacto = Rutina(
  id: 'cardio-bajo-impacto',
  nombre: 'Cardio bajo impacto',
  duracionMin: 15,
  material: 'Sin material',
  impacto: 'bajo',
  porque: 'Sube las pulsaciones sin saltos, así que las rodillas y la espalda '
      'no pagan el precio.',
  notaAdaptacion: 'Se puede hacer entera sentada si hoy no toca estar de pie.',
  pasos: [
    _trabajo(
      'Marcha activa',
      'Marcha en el sitio moviendo los brazos',
      50,
      'Marca el ritmo con los brazos; los pies lo siguen.',
    ),
    _descanso(20, 'Toques de talón'),
    _trabajo(
      'Toques de talón',
      'Adelanta un talón y vuelve, alternando',
      50,
      'Sin saltar: un pie siempre toca el suelo.',
    ),
    _descanso(20, 'Empujes de brazos'),
    _trabajo(
      'Empujes de brazos',
      'Empuja al frente alternando los brazos',
      50,
      'Acompaña cada empuje con una espiración.',
    ),
  ],
);

final Rutina estiramientoLargo = Rutina(
  id: 'estiramiento-largo',
  nombre: 'Estiramiento largo',
  duracionMin: 20,
  material: 'Silla o pared',
  impacto: 'muy bajo',
  porque: 'Un día de descanso activo mantiene el hábito sin acumular fatiga.',
  notaAdaptacion: 'Las posturas se sostienen con apoyo; no hay que bajar al '
      'suelo en ningún momento.',
  pasos: [
    _trabajo(
      'Cuello y trapecio',
      'Inclina la cabeza y sostén',
      60,
      'Deja caer el peso del brazo para abrir más.',
    ),
    _descanso(20, 'Isquiotibiales con apoyo'),
    _trabajo(
      'Isquiotibiales con apoyo',
      'Talón adelante y pecho al frente',
      60,
      'Mantén la rodilla casi recta y la espalda larga.',
    ),
    _descanso(20, 'Cadera y glúteo'),
    _trabajo(
      'Cadera y glúteo',
      'Tobillo sobre la rodilla contraria, sentada',
      60,
      'Inclínate hacia delante solo hasta notar tensión, nunca dolor.',
    ),
  ],
);

/// Todas las rutinas disponibles. El orden es el del índice de Entreno.
final List<Rutina> todasLasRutinas = [
  fuerzaSentada,
  movilidadHombro,
  coreEnSilla,
  cardioBajoImpacto,
  estiramientoLargo,
];

Rutina? rutinaPorId(String id) {
  for (final rutina in todasLasRutinas) {
    if (rutina.id == id) return rutina;
  }
  return null;
}

/// Rutina recomendada del día (RF-40).
///
/// Es determinista por fecha para que la recomendación no cambie al volver a
/// entrar, y respeta el objetivo declarado.
Rutina rutinaRecomendada({
  required Objetivo objetivo,
  required Preferencias preferencias,
  required DateTime fecha,
}) {
  final candidatas = switch (objetivo) {
    Objetivo.ganarFuerza => [fuerzaSentada, coreEnSilla, fuerzaSentada],
    Objetivo.perderPeso => [cardioBajoImpacto, coreEnSilla, fuerzaSentada],
    Objetivo.mantenerMovilidad => [
        movilidadHombro,
        estiramientoLargo,
        coreEnSilla,
      ],
  };
  final dias = fecha.difference(DateTime(2026)).inDays;
  return candidatas[dias.abs() % candidatas.length];
}

/// Nota de adaptación combinada, según las necesidades activas (RF-40, RF-62).
String notaAdaptacionPara(Rutina rutina, Preferencias preferencias) {
  final extras = <String>[];
  if (preferencias.subtitulos) {
    extras.add('Verás subtitulada cada señal sonora y la cuenta atrás en '
        'pantalla.');
  }
  if (preferencias.vibracion) {
    extras.add('El teléfono vibrará al empezar la fase, tres segundos antes '
        'del final y al terminar.');
  }
  if (preferencias.instruccionesCortas) {
    extras.add('Cada paso muestra una sola indicación.');
  }
  return [rutina.notaAdaptacion, ...extras].join(' ');
}
