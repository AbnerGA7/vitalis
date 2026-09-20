/// Catálogo de platos por preferencia dietética, en clave peruana.
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
      PlatoBase('Tamal de pollo', ['choclo', 'pollo', 'huevo']),
      PlatoBase('Pan con palta y huevo', ['pan integral', 'palta', 'huevo']),
      PlatoBase('Quinua con leche y plátano', [
        'quinua',
        'leche',
        'plátano',
      ]),
    ],
    [
      PlatoBase('Lomo saltado ligero con arroz', [
        'lomo de res',
        'arroz',
        'tomate',
      ]),
      PlatoBase('Pollo a la plancha con camote', [
        'pollo',
        'camote',
        'brócoli',
      ]),
      PlatoBase('Pescado sudado con yuca', ['pescado', 'yuca', 'cebolla']),
    ],
    [
      PlatoBase('Yogur con quinua pop y fruta', [
        'yogur',
        'quinua pop',
        'fruta',
      ]),
      PlatoBase('Tostada de atún y palta', ['atún', 'palta', 'pan integral']),
      PlatoBase('Choclo con queso fresco', ['choclo', 'queso fresco']),
    ],
    [
      PlatoBase('Aguadito de pollo', ['pollo', 'arroz', 'culantro']),
      PlatoBase('Tortilla de verduras con camote', [
        'huevo',
        'verduras',
        'camote',
      ]),
      PlatoBase('Pescado al horno con ensalada', [
        'pescado',
        'lechuga',
        'tomate',
      ]),
    ],
  ],
  PreferenciaDieta.vegetariana: [
    [
      PlatoBase('Quinua con leche y plátano', [
        'quinua',
        'leche',
        'plátano',
      ]),
      PlatoBase('Pan con palta y queso', [
        'pan integral',
        'palta',
        'queso fresco',
      ]),
      PlatoBase('Avena con maca y fruta', ['avena', 'maca', 'fruta']),
    ],
    [
      PlatoBase('Tacu tacu de frejoles', ['frejoles', 'arroz', 'huevo']),
      PlatoBase('Menestra de lentejas con arroz', [
        'lentejas',
        'arroz',
        'zapallo',
      ]),
      PlatoBase('Quinua a la jardinera', [
        'quinua',
        'verduras',
        'queso parmesano',
      ]),
    ],
    [
      PlatoBase('Queso fresco con choclo', ['queso fresco', 'choclo']),
      PlatoBase('Yogur con granola andina', [
        'yogur',
        'granola',
        'kiwicha',
      ]),
      PlatoBase('Humita dulce', ['choclo', 'leche', 'canela']),
    ],
    [
      PlatoBase('Causa de verduras', ['papa amarilla', 'palta', 'verduras']),
      PlatoBase('Tortilla de verduras con quinua', [
        'huevo',
        'verduras',
        'quinua',
      ]),
      PlatoBase('Crema de zapallo con semillas', [
        'zapallo',
        'semillas de zapallo',
        'leche',
      ]),
    ],
  ],
  PreferenciaDieta.sinLactosa: [
    [
      PlatoBase('Tamal de pollo', ['choclo', 'pollo', 'huevo']),
      PlatoBase('Pan con palta y huevo', ['pan integral', 'palta', 'huevo']),
      PlatoBase('Quinua con leche de almendra y fruta', [
        'quinua',
        'leche de almendra',
        'fruta',
      ]),
    ],
    [
      PlatoBase('Lomo saltado ligero con arroz', [
        'lomo de res',
        'arroz',
        'tomate',
      ]),
      PlatoBase('Pollo al horno con camote', [
        'pollo',
        'camote',
        'ensalada',
      ]),
      PlatoBase('Pescado a la plancha con yuca', [
        'pescado',
        'yuca',
        'cebolla',
      ]),
    ],
    [
      PlatoBase('Tostada de atún y palta', ['atún', 'palta', 'pan integral']),
      PlatoBase('Choclo con habas', ['choclo', 'habas']),
      PlatoBase('Fruta con quinua pop', ['fruta', 'quinua pop']),
    ],
    [
      PlatoBase('Aguadito de pollo', ['pollo', 'arroz', 'culantro']),
      PlatoBase('Pescado al horno con ensalada', [
        'pescado',
        'lechuga',
        'tomate',
      ]),
      PlatoBase('Tortilla de verduras con camote', [
        'huevo',
        'verduras',
        'camote',
      ]),
    ],
  ],
};
