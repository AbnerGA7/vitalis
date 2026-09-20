// Tipo de mensaje según la intención y si vino del modelo real. ADR-03.
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis/dominio/modelos/enums.dart';
import 'package:vitalis/dominio/modelos/mensaje.dart';

void main() {
  test('lo reconocido mapea a su tarjeta correspondiente', () {
    expect(Mensaje.tipoDeIntencion(Intencion.plan), TipoMensaje.plan);
    expect(Mensaje.tipoDeIntencion(Intencion.agua), TipoMensaje.agua);
    expect(Mensaje.tipoDeIntencion(Intencion.entreno), TipoMensaje.entreno);
  });

  test('lo no reconocido sin modelo real es «no entendido», con ejemplos', () {
    expect(
      Mensaje.tipoDeIntencion(Intencion.desconocida),
      TipoMensaje.noEntendido,
    );
    expect(
      Mensaje.tipoDeIntencion(Intencion.desconocida, esConversacionLibre: false),
      TipoMensaje.noEntendido,
    );
  });

  test('lo no reconocido con modelo real es conversación libre, sin ejemplos', () {
    expect(
      Mensaje.tipoDeIntencion(Intencion.desconocida, esConversacionLibre: true),
      TipoMensaje.conversacionLibre,
    );
  });
}
