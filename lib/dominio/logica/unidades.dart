/// Conversión entre métrico e imperial. RF-02.
///
/// El almacenamiento interno es siempre métrico; estas funciones solo existen
/// para presentar y para leer lo que la persona teclea (sección 4.1).
library;

const double _kgPorLibra = 0.45359237;
const double _cmPorPulgada = 2.54;
const int _pulgadasPorPie = 12;

double librasAKg(double libras) => libras * _kgPorLibra;

double kgALibras(double kg) => kg / _kgPorLibra;

double pulgadasACm(double pulgadas) => pulgadas * _cmPorPulgada;

double cmAPulgadas(double cm) => cm / _cmPorPulgada;

/// Altura imperial descompuesta en pies y pulgadas.
typedef AlturaImperial = ({int pies, int pulgadas});

AlturaImperial cmAPiesPulgadas(double cm) {
  final totalPulgadas = cmAPulgadas(cm).round();
  return (
    pies: totalPulgadas ~/ _pulgadasPorPie,
    pulgadas: totalPulgadas % _pulgadasPorPie,
  );
}

double piesPulgadasACm(int pies, int pulgadas) =>
    pulgadasACm((pies * _pulgadasPorPie) + pulgadas.toDouble());

/// Número con coma decimal, sin decimales sobrantes.
String formatearNumero(double valor, {int decimales = 1}) {
  final texto = valor.toStringAsFixed(decimales);
  final limpio = decimales > 0 && texto.endsWith('0' * decimales)
      ? valor.toStringAsFixed(0)
      : texto;
  return limpio.replaceAll('.', ',');
}
