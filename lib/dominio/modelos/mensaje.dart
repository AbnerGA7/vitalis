/// Mensajes de la conversación con el asistente. Sección 5.
///
/// Son efímeros: la conversación arranca vacía cada día (RF-16) y nunca se
/// guardan en disco.
library;

import 'enums.dart';
import 'plan_comidas.dart';

enum Autor { persona, asistente }

/// Tipo de carga que acompaña a la respuesta del asistente (RF-13).
enum TipoMensaje { texto, plan, agua, entreno, noEntendido }

class Mensaje {
  const Mensaje({
    required this.autor,
    required this.texto,
    this.tipo = TipoMensaje.texto,
    this.plan,
    this.ejemplos = const [],
  });

  const Mensaje.persona(this.texto)
      : autor = Autor.persona,
        tipo = TipoMensaje.texto,
        plan = null,
        ejemplos = const [];

  final Autor autor;
  final String texto;
  final TipoMensaje tipo;

  /// Plan que acompaña a la tarjeta de respuesta (RF-13).
  final PlanComidas? plan;

  /// Ejemplos que se ofrecen cuando no se ha entendido (RF-12).
  final List<String> ejemplos;

  static TipoMensaje tipoDeIntencion(Intencion intencion) =>
      switch (intencion) {
        Intencion.plan => TipoMensaje.plan,
        Intencion.agua => TipoMensaje.agua,
        Intencion.entreno => TipoMensaje.entreno,
        Intencion.desconocida => TipoMensaje.noEntendido,
      };
}
