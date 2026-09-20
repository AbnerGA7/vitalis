/// Enumeraciones del dominio de Vitalis.
///
/// Trazabilidad: RF-04, RF-05, RF-20, RF-21, secciones 4.2 y 5 de la
/// documentación de desarrollo.
library;

/// Objetivo que declara la persona en onboarding y puede editar en Perfil.
///
/// Requisito RF-04.
enum Objetivo {
  perderPeso('Perder peso', TasaProteina.recomposicion),
  ganarFuerza('Ganar fuerza', TasaProteina.fuerza),
  mantenerMovilidad('Mantener movilidad', TasaProteina.mantener);

  const Objetivo(this.etiqueta, this.tasaSugerida);

  final String etiqueta;

  /// Tasa de proteína que Vitalis propone para este objetivo.
  ///
  /// Resuelve el «punto por aclarar» del Anexo A: la tasa se **deriva** del
  /// objetivo, pero sigue siendo editable en Dieta (ver [Perfil.tasaProteina]).
  final TasaProteina tasaSugerida;
}

/// Gramos de proteína por kilo de peso. Sección 4.2.
enum TasaProteina {
  mantener('Mantener', 1.2),
  fuerza('Fuerza', 1.6),
  recomposicion('Recomposición', 2.0);

  const TasaProteina(this.etiqueta, this.gPorKg);

  final String etiqueta;
  final double gPorKg;
}

/// Preferencia dietética. Solo cambia el catálogo de platos (RF-21).
enum PreferenciaDieta {
  mixta('Mixta'),
  vegetariana('Vegetariana'),
  sinLactosa('Sin lactosa');

  const PreferenciaDieta(this.etiqueta);

  final String etiqueta;
}

/// Necesidades de accesibilidad declarables. Se acumulan (RF-62, sección 6).
enum Necesidad {
  bajaVision(
    'Ceguera o baja visión',
    'Vibración, tipografía mayor y anuncios del lector de pantalla',
  ),
  hipoacusia(
    'Sordera o hipoacusia',
    'Subtítulos de toda señal sonora y destello al terminar el descanso',
  ),
  movilidadReducida(
    'Movilidad reducida',
    'Rutinas de bajo impacto y áreas táctiles amplias',
  ),
  apoyoCognitivo(
    'Apoyo cognitivo o de memoria',
    'Instrucciones cortas y una sola acción por tarjeta',
  );

  const Necesidad(this.etiqueta, this.descripcion);

  final String etiqueta;
  final String descripcion;
}

/// Sistema de unidades. El almacenamiento interno siempre es métrico
/// (sección 4.1); lo imperial es solo presentación. RF-02.
enum Unidades {
  metrico('Métrico', 'kg / cm'),
  imperial('Imperial', 'lb / ft·in');

  const Unidades(this.etiqueta, this.detalle);

  final String etiqueta;
  final String detalle;
}

/// Tema visual. Oscuro por defecto y de alto contraste (RNF-03, RNF-07).
enum TemaApp {
  oscuro('Oscuro'),
  claro('Claro');

  const TemaApp(this.etiqueta);

  final String etiqueta;
}

/// Tipo de paso dentro de una rutina. Sección 4.5.
enum TipoPaso { trabajo, descanso }

/// Intención detectada por el asistente. Sección 4.6.
enum Intencion { plan, agua, entreno, desconocida }
