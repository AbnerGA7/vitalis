/// Catálogo de platos por preferencia dietética.
///
/// La preferencia solo cambia este catálogo, nunca el objetivo de proteína
/// (RF-21, sección 4.3). Cada franja tiene varias opciones para que
/// «Regenerar» (RF-24) devuelva un plan distinto.
library;

import '../modelos/enums.dart';

/// Plato sin cantidades: los gramos los reparte el generador del plan.
class PlatoBase {
  const PlatoBase(this.nombre, this.ingredientes);

  final String nombre;
  final List<String> ingredientes;
}

/// Horas de las cuatro comidas. Sección 4.3.
const List<String> horasComidas = ['08:00', '13:00', '16:30', '20:00'];

/// Nombres de franja, para los textos de la interfaz.
const List<String> nombresFranjas = ['Desayuno', 'Comida', 'Merienda', 'Cena'];

const Map<PreferenciaDieta, List<List<PlatoBase>>> catalogoPlatos = {
  PreferenciaDieta.mixta: [
    [
      PlatoBase('Tortilla con avena', ['huevo', 'clara', 'avena', 'plátano']),
      PlatoBase('Requesón con fruta', ['requesón', 'arándanos', 'nueces']),
      PlatoBase('Revuelto de pavo', ['pavo', 'huevo', 'pan integral']),
    ],
    [
      PlatoBase('Pollo con arroz y judías', ['pollo', 'arroz', 'judías verdes']),
      PlatoBase('Ternera con quinoa', ['ternera magra', 'quinoa', 'pimiento']),
      PlatoBase('Lentejas con bacalao', ['lentejas', 'bacalao', 'zanahoria']),
    ],
    [
      PlatoBase('Yogur griego con nueces', ['yogur griego', 'nueces', 'miel']),
      PlatoBase('Tostada de atún', ['atún', 'pan integral', 'tomate']),
      PlatoBase('Batido de leche y avena', ['leche', 'avena', 'cacao']),
    ],
    [
      PlatoBase('Merluza con patata', ['merluza', 'patata', 'brócoli']),
      PlatoBase('Salmón al horno', ['salmón', 'calabacín', 'aceite de oliva']),
      PlatoBase('Tortilla de espinacas', ['huevo', 'espinacas', 'queso fresco']),
    ],
  ],
  PreferenciaDieta.vegetariana: [
    [
      PlatoBase('Avena con yogur y semillas', [
        'avena',
        'yogur',
        'semillas de chía',
      ]),
      PlatoBase('Tostada de hummus y huevo', [
        'hummus',
        'huevo',
        'pan integral',
      ]),
      PlatoBase('Batido de plátano y soja', [
        'bebida de soja',
        'plátano',
        'almendra',
      ]),
    ],
    [
      PlatoBase('Garbanzos con espinacas', [
        'garbanzos',
        'espinacas',
        'comino',
      ]),
      PlatoBase('Tofu salteado con arroz', [
        'tofu',
        'arroz integral',
        'brócoli',
      ]),
      PlatoBase('Lentejas con verduras', ['lentejas', 'zanahoria', 'puerro']),
    ],
    [
      PlatoBase('Queso fresco con nueces', [
        'queso fresco',
        'nueces',
        'manzana',
      ]),
      PlatoBase('Yogur con granola', ['yogur', 'granola', 'frutos rojos']),
      PlatoBase('Edamame con sésamo', ['edamame', 'sésamo', 'lima']),
    ],
    [
      PlatoBase('Tortilla de patata y guisantes', [
        'huevo',
        'patata',
        'guisantes',
      ]),
      PlatoBase('Tempeh con verduras', ['tempeh', 'calabacín', 'pimiento']),
      PlatoBase('Crema de calabaza con semillas', [
        'calabaza',
        'semillas de calabaza',
        'queso',
      ]),
    ],
  ],
  PreferenciaDieta.sinLactosa: [
    [
      PlatoBase('Tortilla con avena', ['huevo', 'clara', 'avena', 'plátano']),
      PlatoBase('Tostada de pavo y aguacate', [
        'pavo',
        'aguacate',
        'pan integral',
      ]),
      PlatoBase('Batido de bebida de soja', [
        'bebida de soja',
        'avena',
        'fresa',
      ]),
    ],
    [
      PlatoBase('Pollo con arroz y judías', ['pollo', 'arroz', 'judías verdes']),
      PlatoBase('Salmón con boniato', ['salmón', 'boniato', 'espárragos']),
      PlatoBase('Garbanzos con atún', ['garbanzos', 'atún', 'tomate']),
    ],
    [
      PlatoBase('Hummus con crudités', ['hummus', 'zanahoria', 'apio']),
      PlatoBase('Almendras con pavo', ['almendras', 'pavo', 'manzana']),
      PlatoBase('Tostada de atún', ['atún', 'pan integral', 'tomate']),
    ],
    [
      PlatoBase('Merluza con patata', ['merluza', 'patata', 'brócoli']),
      PlatoBase('Pollo al horno con verduras', [
        'pollo',
        'calabacín',
        'cebolla',
      ]),
      PlatoBase('Tortilla de espinacas', ['huevo', 'espinacas', 'aguacate']),
    ],
  ],
};
