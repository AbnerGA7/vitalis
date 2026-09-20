/// Reglas de las señales del reproductor. Sección 6 · RF-45, RF-60, RF-61.
///
/// Toda señal tiene al menos dos canales; estas constantes fijan los límites
/// que no pueden cambiar por motivos visuales.
library;

/// Duración del destello verde de fin de descanso.
///
/// Excepción consciente a la regla de Nocturne de «no inundar de color»: es la
/// única señal no sonora del evento, así que prevalece. Se limita a 2,4 s y sin
/// parpadeo rápido para no crear riesgo fotosensible (≤ 3 destellos/s).
const Duration duracionDestello = Duration(milliseconds: 2400);

/// Segundos antes del final en los que se avisa (T-3, RF-61).
const int segundosAvisoPrevio = 3;
