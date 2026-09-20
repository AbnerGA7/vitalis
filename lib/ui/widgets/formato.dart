/// Presentación de medidas según las unidades elegidas. RF-02 · sección 4.1.
///
/// El almacenamiento es siempre métrico: esto es solo la capa de vista.
library;

import '../../dominio/logica/unidades.dart';
import '../../dominio/modelos/enums.dart';

String textoPeso(double kg, Unidades unidades) => switch (unidades) {
      Unidades.metrico => '${formatearNumero(kg, decimales: 0)} kg',
      Unidades.imperial => '${formatearNumero(kgALibras(kg), decimales: 0)} lb',
    };

/// Peso en palabras, para el lector de pantalla.
String pesoHablado(double kg, Unidades unidades) => switch (unidades) {
      Unidades.metrico => '${kg.round()} kilos',
      Unidades.imperial => '${kgALibras(kg).round()} libras',
    };

String textoAltura(double cm, Unidades unidades) {
  if (unidades == Unidades.metrico) {
    return '${formatearNumero(cm, decimales: 0)} cm';
  }
  final altura = cmAPiesPulgadas(cm);
  return '${altura.pies} ft ${altura.pulgadas} in';
}

String alturaHablada(double cm, Unidades unidades) {
  if (unidades == Unidades.metrico) return '${cm.round()} centímetros';
  final altura = cmAPiesPulgadas(cm);
  return '${altura.pies} pies y ${altura.pulgadas} pulgadas';
}

/// Unidad en palabras para los botones de ajuste de 1 unidad (AC-04).
String unidadPesoHablada(Unidades unidades) =>
    unidades == Unidades.metrico ? 'kilo' : 'libra';

String unidadAlturaHablada(Unidades unidades) =>
    unidades == Unidades.metrico ? 'centímetro' : 'pulgada';

String textoMililitros(int ml) => '$ml ml';

String mlHablados(int ml) => '$ml mililitros';
