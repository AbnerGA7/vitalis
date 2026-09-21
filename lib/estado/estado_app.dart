/// Estado compartido de la aplicación. Sección 3 · «Estado compartido».
///
/// Una única fuente de verdad alimenta todas las pantallas: cambiar el peso en
/// Perfil recalcula proteína, plan y respuestas del asistente.
library;

import '../dominio/logica/hidratacion.dart';
import '../dominio/logica/imc.dart';
import '../dominio/logica/proteina.dart';
import '../dominio/modelos/enums.dart';
import '../dominio/modelos/perfil.dart';
import '../dominio/modelos/plan_comidas.dart';
import '../dominio/modelos/rutina.dart';

class EstadoApp {
  const EstadoApp({
    required this.perfil,
    required this.preferencias,
    required this.dia,
    this.plan,
    this.planUsadoHoy = false,
    this.aguaMl = 0,
    this.generandoPlan = false,
    this.pasoGeneracion = 0,
    this.rutinaIA,
    this.generandoRutina = false,
    this.pasoGeneracionRutina = 0,
    this.rutinaIAError,
  });

  final Perfil perfil;
  final Preferencias preferencias;

  /// Día en curso. Al cambiar se reinician agua, plan y conversación.
  final DateTime dia;

  final PlanComidas? plan;

  /// «Usar en el día» ya pulsado para el plan vigente (RF-24).
  final bool planUsadoHoy;

  final int aguaMl;

  /// Estado «pensando/generando» de Dieta (RF-15).
  final bool generandoPlan;
  final int pasoGeneracion;

  /// Rutina de hoy generada por IA, si la hay. `null` cuando todavía no se ha
  /// pedido una o cuando falló: en ese caso Entreno cae al catálogo fijo
  /// (sección 4.5).
  final Rutina? rutinaIA;

  /// Estado «pensando/generando» de Entreno, mismo patrón que Dieta.
  final bool generandoRutina;
  final int pasoGeneracionRutina;

  /// Mensaje del último intento fallido de generar la rutina con IA, o
  /// `null` si no hubo fallo (o si fue el primer intento). A diferencia del
  /// plan de comidas —que siempre cae al catálogo con un plan visible—, la
  /// rutina de hoy ya se ve por defecto (catálogo fijo), así que un fallo
  /// silencioso deja la pantalla exactamente igual que antes de pulsar el
  /// botón: sin este mensaje, parece que «no ha hecho nada».
  final String? rutinaIAError;

  /// Proteína objetivo derivada del peso y la tasa (RF-20, RF-51).
  int get proteinaObjetivo =>
      proteinaObjetivoG(pesoKg: perfil.pesoKg, tasa: perfil.tasaProteina);

  String get formula =>
      formulaProteina(pesoKg: perfil.pesoKg, tasa: perfil.tasaProteina);

  double? get imc =>
      calcularImc(pesoKg: perfil.pesoKg, alturaCm: perfil.alturaCm);

  BandaImc? get bandaImc {
    final valor = imc;
    return valor == null ? null : bandaDeImc(valor);
  }

  double get progresoDeAgua => progresoAgua(aguaMl);

  String get fraseAgua => fraseHidratacion(aguaMl);

  /// El plan deja de valer si cambian peso, tasa o preferencia (sección 5).
  bool get planVigente {
    final actual = plan;
    if (actual == null) return false;
    return actual.objetivoProteinaG == proteinaObjetivo &&
        actual.tasa == perfil.tasaProteina &&
        actual.preferencia == perfil.preferenciaDieta;
  }

  EstadoApp copiarCon({
    Perfil? perfil,
    Preferencias? preferencias,
    DateTime? dia,
    PlanComidas? plan,
    bool limpiarPlan = false,
    bool? planUsadoHoy,
    int? aguaMl,
    bool? generandoPlan,
    int? pasoGeneracion,
    Rutina? rutinaIA,
    bool limpiarRutinaIA = false,
    bool? generandoRutina,
    int? pasoGeneracionRutina,
    String? rutinaIAError,
    bool limpiarRutinaIAError = false,
  }) =>
      EstadoApp(
        perfil: perfil ?? this.perfil,
        preferencias: preferencias ?? this.preferencias,
        dia: dia ?? this.dia,
        plan: limpiarPlan ? null : (plan ?? this.plan),
        planUsadoHoy: planUsadoHoy ?? this.planUsadoHoy,
        aguaMl: aguaMl ?? this.aguaMl,
        generandoPlan: generandoPlan ?? this.generandoPlan,
        pasoGeneracion: pasoGeneracion ?? this.pasoGeneracion,
        rutinaIA: limpiarRutinaIA ? null : (rutinaIA ?? this.rutinaIA),
        generandoRutina: generandoRutina ?? this.generandoRutina,
        pasoGeneracionRutina:
            pasoGeneracionRutina ?? this.pasoGeneracionRutina,
        rutinaIAError: limpiarRutinaIAError
            ? null
            : (rutinaIAError ?? this.rutinaIAError),
      );
}

/// Nombre legible del objetivo para los textos accesibles.
String etiquetaObjetivo(Objetivo objetivo) => objetivo.etiqueta;
