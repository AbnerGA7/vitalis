// Chat de voz completo: dictar envía solo, la respuesta se habla, la
// conversación reinicia la memoria del modelo real cada día (RF-16).
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis/estado/estado_conversacion.dart';
import 'package:vitalis/estado/notificador_app.dart';
import 'package:vitalis/servicios/contratos/contratos.dart';

import '../dobles/entorno.dart';

/// Un pelín más que la pausa interna entre pasos de `enviar()`, para dejar
/// que el envío disparado por voz («fire and forget») termine antes de que
/// la prueba acabe y desmonte el contenedor.
Future<void> _esperarRespuesta() =>
    Future<void>.delayed(pausaEntrePasosGeneracion * 2);

void main() {
  test('al terminar de dictar, el mensaje se envía solo', () async {
    final entorno = Entorno();
    final contenedor = entorno.contenedor();
    final notificador = contenedor.read(conversacionProvider.notifier);

    await notificador.iniciarDictado();
    entorno.voz.transcribir('apunta un vaso de agua', definitiva: true);
    await _esperarRespuesta();

    final mensajes = contenedor.read(conversacionProvider).mensajes;
    expect(mensajes, isNotEmpty);
    expect(mensajes.first.texto, 'apunta un vaso de agua');
  });

  test('una transcripción parcial no envía nada todavía', () async {
    final entorno = Entorno();
    final contenedor = entorno.contenedor();
    final notificador = contenedor.read(conversacionProvider.notifier);

    await notificador.iniciarDictado();
    entorno.voz.transcribir('apunta', definitiva: false);
    await Future<void>.delayed(Duration.zero);

    expect(contenedor.read(conversacionProvider).mensajes, isEmpty);
    expect(contenedor.read(conversacionProvider).borrador, 'apunta');
  });

  test('la respuesta del asistente se dice en voz alta', () async {
    final entorno = Entorno();
    final contenedor = entorno.contenedor();
    final notificador = contenedor.read(conversacionProvider.notifier);

    await notificador.enviar('apunta un vaso de agua');

    expect(entorno.sintesisVoz.dicho, hasLength(1));
    expect(entorno.sintesisVoz.dicho.first, contains('mililitros'));
  });

  test(
      'el modo manos-libres reabre el dictado solo tras cada respuesta, sin '
      'volver a tocar el micro', () async {
    final entorno = Entorno();
    final contenedor = entorno.contenedor();
    final notificador = contenedor.read(conversacionProvider.notifier);

    await notificador.iniciarDictado();
    entorno.voz.transcribir('apunta un vaso de agua', definitiva: true);
    await _esperarRespuesta();

    // Sin tocar el micro otra vez, ya debería estar escuchando de nuevo.
    expect(contenedor.read(conversacionProvider).escuchando, isTrue);
    expect(entorno.voz.escuchando, isTrue);

    // Un segundo turno por voz, otra vez sin tocar nada.
    entorno.voz.transcribir('¿qué entreno toca hoy?', definitiva: true);
    await _esperarRespuesta();

    final mensajes = contenedor.read(conversacionProvider).mensajes;
    expect(mensajes.where((m) => m.autor.name == 'persona'), hasLength(2));
  });

  test('si el dictado falla, el modo manos-libres no se queda encendido',
      () async {
    final entorno = Entorno(hayDictado: false);
    final contenedor = entorno.contenedor();
    final notificador = contenedor.read(conversacionProvider.notifier);

    await notificador.iniciarDictado();

    final estado = contenedor.read(conversacionProvider);
    expect(estado.modoVozContinua, isFalse);
    expect(estado.errorVoz, isNotNull);
  });

  test('escribir a mano apaga el modo manos-libres', () async {
    final entorno = Entorno();
    final contenedor = entorno.contenedor();
    final notificador = contenedor.read(conversacionProvider.notifier);

    await notificador.iniciarDictado();
    entorno.voz.transcribir('apunta un vaso de agua', definitiva: true);
    await _esperarRespuesta();
    expect(contenedor.read(conversacionProvider).modoVozContinua, isTrue);

    notificador.escribir('esto lo escribo yo');

    expect(contenedor.read(conversacionProvider).modoVozContinua, isFalse);
  });

  test('vaciar la conversación también reinicia la memoria del modelo real',
      () async {
    final entorno = Entorno(estadoModeloIA: EstadoModeloIA.listo);
    final contenedor = entorno.contenedor();
    final notificador = contenedor.read(conversacionProvider.notifier);

    entorno.conversadorIA.respuesta = 'Claro, prueba con esto.';
    await notificador.enviar('¿me recomiendas algo para hoy?');
    expect(entorno.conversadorIA.instruccionRecibida, isNotNull);

    notificador.vaciar();
    await notificador.enviar('otra pregunta cualquiera');

    // reiniciar() se llamó de nuevo: la conversación de hoy no arrastra la
    // memoria del modelo del día anterior.
    expect(entorno.conversadorIA.mensajesRecibidos, ['otra pregunta cualquiera']);
  });
}
