/// Perfil y preferencias. Sección 5 · RF-50.
///
/// Un solo perfil por dispositivo (supuesto del Anexo A). Todo se guarda
/// localmente y nada sale del teléfono (RNF-01).
library;

import 'enums.dart';

/// Rangos plausibles de peso y altura (supuesto del Anexo A, pendiente de
/// validar con producto). Se usan para validar al editar.
const double pesoMinimoKg = 30;
const double pesoMaximoKg = 250;
const double alturaMinimaCm = 100;
const double alturaMaximaCm = 230;

double acotarPeso(double kg) => kg.clamp(pesoMinimoKg, pesoMaximoKg);

double acotarAltura(double cm) => cm.clamp(alturaMinimaCm, alturaMaximaCm);

/// Datos corporales y de dieta. El almacenamiento es siempre métrico.
class Perfil {
  const Perfil({
    required this.pesoKg,
    required this.alturaCm,
    required this.objetivo,
    required this.tasaProteina,
    required this.preferenciaDieta,
    this.comidasFavoritas = '',
    this.ingredientesEvitar = '',
  });

  /// Perfil de arranque antes del onboarding.
  factory Perfil.inicial() => const Perfil(
        pesoKg: 70,
        alturaCm: 170,
        objetivo: Objetivo.mantenerMovilidad,
        tasaProteina: TasaProteina.mantener,
        preferenciaDieta: PreferenciaDieta.mixta,
      );

  final double pesoKg;
  final double alturaCm;
  final Objetivo objetivo;

  /// Tasa efectiva. Se deriva del objetivo al elegirlo, pero puede ajustarse
  /// a mano en Dieta (resolución del «punto por aclarar» del Anexo A).
  final TasaProteina tasaProteina;

  final PreferenciaDieta preferenciaDieta;

  /// Comidas o ingredientes que le gustan a la persona, texto libre separado
  /// por comas (p. ej. «pollo, palta, quinua»). Sesga los platos del
  /// catálogo hacia esas coincidencias y se incluye en el pedido a la IA al
  /// generar recetas (sección 4.3). Nunca cambia la proteína objetivo.
  final String comidasFavoritas;

  /// Ingredientes que la persona no quiere ver en sus comidas (p. ej.
  /// «tomate, cebolla»), mismo formato que [comidasFavoritas]. Excluye del
  /// catálogo los platos que los contengan (si eso deja alguna franja sin
  /// opciones, esa franja ignora el filtro para no dejar la comida vacía) y
  /// se lo pide también a la IA al generar recetas.
  final String ingredientesEvitar;

  Perfil copiarCon({
    double? pesoKg,
    double? alturaCm,
    Objetivo? objetivo,
    TasaProteina? tasaProteina,
    PreferenciaDieta? preferenciaDieta,
    String? comidasFavoritas,
    String? ingredientesEvitar,
  }) =>
      Perfil(
        pesoKg: pesoKg ?? this.pesoKg,
        alturaCm: alturaCm ?? this.alturaCm,
        objetivo: objetivo ?? this.objetivo,
        tasaProteina: tasaProteina ?? this.tasaProteina,
        preferenciaDieta: preferenciaDieta ?? this.preferenciaDieta,
        comidasFavoritas: comidasFavoritas ?? this.comidasFavoritas,
        ingredientesEvitar: ingredientesEvitar ?? this.ingredientesEvitar,
      );

  /// Cambia el objetivo arrastrando la tasa sugerida.
  Perfil conObjetivo(Objetivo nuevo) =>
      copiarCon(objetivo: nuevo, tasaProteina: nuevo.tasaSugerida);

  Map<String, Object?> aJson() => {
        'pesoKg': pesoKg,
        'alturaCm': alturaCm,
        'objetivo': objetivo.name,
        'tasaProteina': tasaProteina.name,
        'preferenciaDieta': preferenciaDieta.name,
        'comidasFavoritas': comidasFavoritas,
        'ingredientesEvitar': ingredientesEvitar,
      };

  static Perfil desdeJson(Map<String, Object?> json) => Perfil(
        pesoKg: (json['pesoKg'] as num).toDouble(),
        alturaCm: (json['alturaCm'] as num).toDouble(),
        objetivo: Objetivo.values.byName(json['objetivo'] as String),
        tasaProteina: TasaProteina.values.byName(json['tasaProteina'] as String),
        preferenciaDieta:
            PreferenciaDieta.values.byName(json['preferenciaDieta'] as String),
        // `as String? ?? ''`: perfiles guardados antes de este campo no lo
        // tienen, y no debe romper la lectura de un perfil ya existente.
        comidasFavoritas: json['comidasFavoritas'] as String? ?? '',
        ingredientesEvitar: json['ingredientesEvitar'] as String? ?? '',
      );
}

/// Unidades, tema, necesidades y estado del onboarding.
class Preferencias {
  const Preferencias({
    required this.unidades,
    required this.tema,
    required this.necesidades,
    required this.onboardingCompletado,
  });

  factory Preferencias.inicial() => const Preferencias(
        unidades: Unidades.metrico,
        tema: TemaApp.oscuro,
        necesidades: {},
        onboardingCompletado: false,
      );

  final Unidades unidades;
  final TemaApp tema;

  /// Las necesidades se acumulan; nunca son excluyentes (RF-62).
  final Set<Necesidad> necesidades;

  final bool onboardingCompletado;

  bool get subtitulos => necesidades.contains(Necesidad.hipoacusia);

  bool get vibracion => necesidades.contains(Necesidad.bajaVision);

  bool get tipografiaMayor => necesidades.contains(Necesidad.bajaVision);

  bool get instruccionesCortas => necesidades.contains(Necesidad.apoyoCognitivo);

  bool get bajoImpacto => necesidades.contains(Necesidad.movilidadReducida);

  Preferencias copiarCon({
    Unidades? unidades,
    TemaApp? tema,
    Set<Necesidad>? necesidades,
    bool? onboardingCompletado,
  }) =>
      Preferencias(
        unidades: unidades ?? this.unidades,
        tema: tema ?? this.tema,
        necesidades: necesidades ?? this.necesidades,
        onboardingCompletado: onboardingCompletado ?? this.onboardingCompletado,
      );

  Preferencias alternarNecesidad(Necesidad necesidad) {
    final copia = Set<Necesidad>.from(necesidades);
    if (!copia.remove(necesidad)) copia.add(necesidad);
    return copiarCon(necesidades: copia);
  }

  Map<String, Object?> aJson() => {
        'unidades': unidades.name,
        'tema': tema.name,
        'necesidades': necesidades.map((n) => n.name).toList(),
        'onboardingCompletado': onboardingCompletado,
      };

  static Preferencias desdeJson(Map<String, Object?> json) => Preferencias(
        unidades: Unidades.values.byName(json['unidades'] as String),
        tema: TemaApp.values.byName(json['tema'] as String),
        necesidades: (json['necesidades'] as List<Object?>)
            .map((n) => Necesidad.values.byName(n as String))
            .toSet(),
        onboardingCompletado: json['onboardingCompletado'] as bool,
      );
}
