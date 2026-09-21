/// Motor de IA local por reglas. ADR-03 · RNF-01, RNF-09.
///
/// Decisión tomada para v1: reglas y plantillas deterministas detrás del
/// contrato [MotorIA]. Corre en el dispositivo, no abre ninguna conexión y
/// funciona igual en gama baja. Sustituir esto por un modelo pequeño en el
/// dispositivo no obliga a tocar ni la interfaz ni el estado.
library;

import '../../dominio/logica/clasificador_intenciones.dart';
import '../../dominio/logica/generador_plan.dart';
import '../../dominio/logica/hidratacion.dart';
import '../../dominio/modelos/enums.dart';
import '../../dominio/modelos/mensaje.dart';
import '../../dominio/modelos/plan_comidas.dart';
import '../contratos/contratos.dart';

class MotorIALocal implements MotorIA {
  const MotorIALocal({
    required this.obtenerContexto,
    this.reloj = const RelojDelSistemaParaMotor(),
  });

  /// Lo que el motor necesita saber del estado en el momento de responder.
  final ContextoAsistente Function() obtenerContexto;

  final Reloj reloj;

  @override
  List<String> get pasosDeGeneracion => const [
        'Leyendo tu perfil',
        'Repartiendo los gramos',
        'Eligiendo platos',
        'Comprobando las kilocalorías',
      ];

  @override
  Future<PlanComidas> generarPlan({
    required double pesoKg,
    required TasaProteina tasa,
    required PreferenciaDieta preferencia,
    int semilla = 0,
    String comidasFavoritas = '',
    String ingredientesEvitar = '',
  }) async =>
      generarPlanDelDia(
        pesoKg: pesoKg,
        tasa: tasa,
        preferencia: preferencia,
        fecha: reloj.ahora(),
        semilla: semilla,
        comidasFavoritas: comidasFavoritas,
        ingredientesEvitar: ingredientesEvitar,
      );

  /// Sin modelo de lenguaje real detrás, este motor nunca inventa fuera de
  /// las tres intenciones reconocidas (sección 4.6).
  @override
  bool get conversacionDisponible => false;

  @override
  Future<RespuestaAsistente> responder(
    String texto, {
    List<Mensaje> historial = const [],
  }) async {
    final intencion = clasificarIntencion(texto);
    final contexto = obtenerContexto();

    switch (intencion) {
      case Intencion.plan:
        final plan = await generarPlan(
          pesoKg: contexto.pesoKg,
          tasa: contexto.tasa,
          preferencia: contexto.preferencia,
          semilla: reloj.ahora().millisecondsSinceEpoch,
          comidasFavoritas: contexto.comidasFavoritas,
          ingredientesEvitar: contexto.ingredientesEvitar,
        );
        return RespuestaAsistente(
          intencion: intencion,
          texto: 'Hoy te tocan ${plan.objetivoProteinaG} g de proteína. '
              'Te he repartido cuatro comidas; puedes usarlas tal cual o '
              'pedirme otras.',
          plan: plan,
        );

      case Intencion.agua:
        return RespuestaAsistente(
          intencion: intencion,
          texto: 'Llevas ${contexto.aguaMl} de $metaDiariaMl mililitros. '
              '${fraseHidratacion(contexto.aguaMl)}',
        );

      case Intencion.entreno:
        return RespuestaAsistente(
          intencion: intencion,
          texto: 'Hoy te propongo «${contexto.nombreRutina}». '
              'Puedes empezar cuando quieras; el reproductor se adapta a lo '
              'que tengas activado en tu perfil.',
        );

      case Intencion.desconocida:
        return const RespuestaAsistente(
          intencion: Intencion.desconocida,
          texto: textoNoEntendido,
          ejemplos: ejemplosSugeridos,
        );
    }
  }
}

/// Reloj por defecto del motor, para no obligar a inyectarlo en pruebas
/// que no dependen del tiempo.
class RelojDelSistemaParaMotor implements Reloj {
  const RelojDelSistemaParaMotor();

  @override
  DateTime ahora() => DateTime.now();
}
