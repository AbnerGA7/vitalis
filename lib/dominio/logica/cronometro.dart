/// Cronómetro del reproductor. Sección 4.5 · RF-43 · RNF-06.
///
/// El tiempo se calcula por reloj real (marca de inicio de fase), nunca por
/// conteo de ticks, para sobrevivir a pausas del proceso y a la pantalla
/// apagada. Es lógica pura: el instante actual se inyecta en cada consulta.
library;

import '../modelos/rutina.dart';

/// Estado inmutable del cronómetro.
class EstadoCronometro {
  const EstadoCronometro({
    required this.rutina,
    required this.indicePaso,
    required this.inicioFase,
    this.pausadoEn,
    this.terminado = false,
  });

  /// Arranca la rutina en su primer paso.
  factory EstadoCronometro.iniciar(Rutina rutina, DateTime ahora) =>
      EstadoCronometro(rutina: rutina, indicePaso: 0, inicioFase: ahora);

  final Rutina rutina;
  final int indicePaso;

  /// Instante en que empezó la fase actual.
  final DateTime inicioFase;

  /// Instante en que se pulsó pausa; `null` mientras corre.
  final DateTime? pausadoEn;

  final bool terminado;

  bool get enPausa => pausadoEn != null;

  Paso get paso => rutina.pasos[indicePaso];

  int get totalPasos => rutina.pasos.length;

  /// Número de paso legible: «n de N» (RF-43).
  int get numeroPaso => indicePaso + 1;

  bool get esUltimoPaso => indicePaso >= totalPasos - 1;

  /// Segundos transcurridos en la fase actual, congelados si está en pausa.
  int transcurridoS(DateTime ahora) {
    final referencia = pausadoEn ?? ahora;
    final segundos = referencia.difference(inicioFase).inSeconds;
    return segundos < 0 ? 0 : segundos;
  }

  /// Segundos que faltan, nunca negativos.
  int restanteS(DateTime ahora) {
    final restante = paso.duracionS - transcurridoS(ahora);
    return restante < 0 ? 0 : restante;
  }

  /// Progreso de la fase actual, entre 0 y 1.
  double progresoFase(DateTime ahora) {
    if (paso.duracionS <= 0) return 1;
    final progreso = transcurridoS(ahora) / paso.duracionS;
    return progreso.clamp(0.0, 1.0);
  }

  /// Progreso por pasos de toda la rutina (RF-43).
  double get progresoRutina => totalPasos == 0 ? 0 : numeroPaso / totalPasos;

  /// ¿Estamos exactamente a tres segundos del final? Dispara la vibración T-3
  /// del perfil de baja visión (RF-61).
  bool esT3(DateTime ahora) => !enPausa && !terminado && restanteS(ahora) == 3;

  EstadoCronometro copiarCon({
    int? indicePaso,
    DateTime? inicioFase,
    DateTime? pausadoEn,
    bool limpiarPausa = false,
    bool? terminado,
  }) =>
      EstadoCronometro(
        rutina: rutina,
        indicePaso: indicePaso ?? this.indicePaso,
        inicioFase: inicioFase ?? this.inicioFase,
        pausadoEn: limpiarPausa ? null : (pausadoEn ?? this.pausadoEn),
        terminado: terminado ?? this.terminado,
      );

  /// Congela el cronómetro.
  EstadoCronometro pausar(DateTime ahora) =>
      enPausa || terminado ? this : copiarCon(pausadoEn: ahora);

  /// Reanuda reajustando el inicio de fase para no perder lo ya corrido.
  EstadoCronometro reanudar(DateTime ahora) {
    final pausa = pausadoEn;
    if (pausa == null || terminado) return this;
    final desplazamiento = ahora.difference(pausa);
    return copiarCon(
      inicioFase: inicioFase.add(desplazamiento),
      limpiarPausa: true,
    );
  }

  /// Avanza al paso siguiente reiniciando su duración; tras el último, fin.
  EstadoCronometro siguiente(DateTime ahora) {
    if (terminado) return this;
    if (esUltimoPaso) return copiarCon(terminado: true, limpiarPausa: true);
    return copiarCon(
      indicePaso: indicePaso + 1,
      inicioFase: ahora,
      limpiarPausa: true,
    );
  }

  /// Vuelve al paso anterior reiniciando su duración (RF-43).
  EstadoCronometro anterior(DateTime ahora) {
    if (indicePaso == 0) {
      return copiarCon(inicioFase: ahora, limpiarPausa: true);
    }
    return copiarCon(
      indicePaso: indicePaso - 1,
      inicioFase: ahora,
      limpiarPausa: true,
      terminado: false,
    );
  }

  /// Comprueba si la fase ha vencido y, si es así, avanza sola.
  ///
  /// Devuelve el estado resultante; compárelo con `this` para saber si hubo
  /// cambio de fase y disparar las señales correspondientes.
  EstadoCronometro avanzarSiVencio(DateTime ahora) {
    if (terminado || enPausa) return this;
    if (restanteS(ahora) > 0) return this;
    return siguiente(ahora);
  }
}

/// Segundos formateados como cuenta atrás grande del reproductor.
String formatearCuentaAtras(int segundos) {
  if (segundos < 60) return '$segundos';
  final minutos = segundos ~/ 60;
  final resto = segundos % 60;
  return '$minutos:${resto.toString().padLeft(2, '0')}';
}
