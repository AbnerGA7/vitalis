// Enrutado del motor híbrido: reglas para lo estructurado, LLM real para la
// conversación libre. ADR-03.
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalis/dominio/modelos/enums.dart';
import 'package:vitalis/servicios/contratos/contratos.dart';
import 'package:vitalis/servicios/impl/motor_ia_hibrido.dart';
import 'package:vitalis/servicios/impl/motor_ia_local.dart';

import '../dobles/dobles.dart';

ContextoAsistente _contexto() => const ContextoAsistente(
      pesoKg: 70,
      tasa: TasaProteina.fuerza,
      preferencia: PreferenciaDieta.mixta,
      aguaMl: 1000,
      nombreRutina: 'Fuerza sentada',
    );

void main() {
  late MotorIALocal reglas;
  late GestorModeloIAFalso gestor;
  late ConversadorIAFalso conversador;
  late MotorIAHibrido hibrido;

  setUp(() {
    reglas = MotorIALocal(obtenerContexto: _contexto);
    gestor = GestorModeloIAFalso();
    conversador = ConversadorIAFalso();
    hibrido = MotorIAHibrido(
      base: reglas,
      gestor: gestor,
      conversador: conversador,
      obtenerContexto: _contexto,
    );
  });

  test('sin modelo cargado, conversacionDisponible es falso', () {
    expect(hibrido.conversacionDisponible, isFalse);
  });

  test('con el modelo listo, conversacionDisponible es verdadero', () {
    gestor.estado = EstadoModeloIA.listo;
    expect(hibrido.conversacionDisponible, isTrue);
  });

  test('lo reconocido sigue resolviéndose por reglas aunque haya modelo', () async {
    gestor.estado = EstadoModeloIA.listo;
    final respuesta = await hibrido.responder('apunta un vaso de agua');
    expect(respuesta.intencion, Intencion.agua);
    expect(respuesta.esConversacionLibre, isFalse);
    expect(conversador.mensajesRecibidos, isEmpty);
  });

  test('generarPlan siempre va por fórmula, nunca por el modelo', () async {
    gestor.estado = EstadoModeloIA.listo;
    final plan = await hibrido.generarPlan(
      pesoKg: 70,
      tasa: TasaProteina.fuerza,
      preferencia: PreferenciaDieta.mixta,
    );
    expect(plan.objetivoProteinaG, 112);
    expect(conversador.mensajesRecibidos, isEmpty);
  });

  test('sin modelo, lo no reconocido cae en el «no entendido» de reglas', () async {
    final respuesta = await hibrido.responder('cuéntame un chiste');
    expect(respuesta.intencion, Intencion.desconocida);
    expect(respuesta.esConversacionLibre, isFalse);
    expect(respuesta.ejemplos, hasLength(3));
    expect(conversador.mensajesRecibidos, isEmpty);
  });

  test('con modelo listo, lo no reconocido conversa de verdad', () async {
    gestor.estado = EstadoModeloIA.listo;
    conversador.respuesta = 'Prueba con una manzana y un puñado de nueces.';
    final respuesta = await hibrido.responder('¿qué merienda me recomiendas?');

    expect(respuesta.intencion, Intencion.desconocida);
    expect(respuesta.esConversacionLibre, isTrue);
    expect(respuesta.texto, contains('manzana'));
    expect(conversador.mensajesRecibidos, ['¿qué merienda me recomiendas?']);
  });

  test('la conversación se inicia una sola vez, no en cada mensaje', () async {
    gestor.estado = EstadoModeloIA.listo;
    await hibrido.responder('cuéntame algo');
    await hibrido.responder('y otra cosa más');

    expect(conversador.instruccionRecibida, isNotNull);
    expect(conversador.mensajesRecibidos, ['cuéntame algo', 'y otra cosa más']);
  });

  test('reiniciarConversacion hace que el siguiente mensaje reabra el chat', () async {
    gestor.estado = EstadoModeloIA.listo;
    await hibrido.responder('hola');
    hibrido.reiniciarConversacion();
    await hibrido.responder('hola de nuevo');

    // reiniciar() abre una conversación nueva, así que el falso descarta el
    // historial anterior: solo queda el mensaje del turno más reciente.
    expect(conversador.mensajesRecibidos, ['hola de nuevo']);
  });

  test('si el modelo falla a media conversación, cae a las reglas', () async {
    gestor.estado = EstadoModeloIA.listo;
    conversador.fallarCon = StateError('el motor se cayó');

    final respuesta = await hibrido.responder('cuéntame algo');

    expect(respuesta.esConversacionLibre, isFalse);
    expect(respuesta.texto, contains('interpretar'));
  });

  test('la instrucción de sistema recoge el contexto de la persona', () {
    final instruccion = instruccionSistemaAsistente(_contexto());
    expect(instruccion, contains('70 kg'));
    expect(instruccion, contains('Fuerza sentada'));
    expect(instruccion, contains('español'));
  });
}
