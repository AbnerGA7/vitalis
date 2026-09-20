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
      );
}

/// Nombre legible del objetivo para los textos accesibles.
String etiquetaObjetivo(Objetivo objetivo) => objetivo.etiqueta;
