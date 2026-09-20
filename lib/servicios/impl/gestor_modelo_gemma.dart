/// Ciclo de vida del modelo de IA local real. ADR-03.
///
/// Envuelve flutter_gemma (motor MediaPipe, ficheros `.task`). El modelo por
/// defecto va empaquetado en la app como asset ([instalarModeloEmpaquetado])
/// y se instala solo al arrancar, sin red: el 100 % offline empieza en el
/// mismo instante en que se instala la app, no cuando alguien pulsa
/// «descargar». La descarga por URL ([descargar]) sigue disponible como vía
/// avanzada para cambiar a otro modelo distinto del que trae la app.
library;

import 'dart:async';

import 'package:flutter_gemma/flutter_gemma.dart';

import '../contratos/contratos.dart';

/// Nombre del fichero que identifica al modelo ya instalado
/// (`FlutterGemma.isModelInstalled` lo compara por nombre de fichero, que es
/// el último segmento de la URL de descarga).
String nombreDeArchivoModelo(String urlModelo) =>
    Uri.parse(urlModelo).pathSegments.last;

/// Ruta del modelo empaquetado, tal y como se declaró en `pubspec.yaml`.
const String rutaModeloEmpaquetado =
    'assets/modelo_ia/qwen2.5-0.5b-instruct-q8.task';

class GestorModeloGemma implements GestorModeloIA {
  GestorModeloGemma();

  EstadoModeloIA _estado = EstadoModeloIA.sinInstalar;
  double _progreso = 0;
  String? _error;
  String? _urlInstalada;
  CancelToken? _cancelToken;
  final StreamController<EstadoModeloIA> _controlador =
      StreamController<EstadoModeloIA>.broadcast();

  @override
  EstadoModeloIA get estado => _estado;

  @override
  Stream<EstadoModeloIA> get cambiosDeEstado => _controlador.stream;

  @override
  double get progreso => _progreso;

  @override
  String? get error => _error;

  /// URL con la que se instaló el modelo activo, si hay uno.
  String? get urlInstalada => _urlInstalada;

  void _cambiar(EstadoModeloIA nuevo) {
    _estado = nuevo;
    if (!_controlador.isClosed) _controlador.add(nuevo);
  }

  /// Instala el modelo que trae la app, si todavía no está instalado.
  ///
  /// Es un asset de Flutter: no hace ninguna petición de red. Se llama una
  /// vez al arrancar, antes de pintar nada, para que el asistente pueda
  /// conversar desde el primer uso.
  Future<void> instalarModeloEmpaquetado() async {
    final nombre = nombreDeArchivoModelo(rutaModeloEmpaquetado);
    try {
      if (await FlutterGemma.isModelInstalled(nombre)) {
        _urlInstalada = rutaModeloEmpaquetado;
        _cambiar(EstadoModeloIA.listo);
        return;
      }

      _cambiar(EstadoModeloIA.descargando);
      await FlutterGemma.installModel(modelType: ModelType.qwen)
          .fromAsset(rutaModeloEmpaquetado)
          .install();
      _urlInstalada = rutaModeloEmpaquetado;
      _progreso = 1;
      _cambiar(EstadoModeloIA.listo);
    } catch (fallo) {
      _error = _explicarError(fallo);
      _cambiar(EstadoModeloIA.error);
    }
  }

  /// Debe llamarse una vez al arrancar si ya había un modelo distinto
  /// descargado por URL en una sesión anterior (la URL se guarda en
  /// Preferencias). No interfiere con el modelo empaquetado: si no hay una
  /// URL guardada, `instalarModeloEmpaquetado` sigue siendo quien decide.
  Future<void> restaurar(String? urlModeloGuardada) async {
    if (urlModeloGuardada == null || urlModeloGuardada.isEmpty) return;
    try {
      final instalado = await FlutterGemma.isModelInstalled(
        nombreDeArchivoModelo(urlModeloGuardada),
      );
      if (instalado) {
        _urlInstalada = urlModeloGuardada;
        _cambiar(EstadoModeloIA.listo);
      }
    } on Exception {
      // Si el fichero desapareció (p. ej. la persona limpió almacenamiento),
      // se queda como sin instalar y lo pedirá de nuevo.
    }
  }

  @override
  Future<void> descargar({
    required String urlModelo,
    String? tokenHuggingFace,
  }) async {
    _error = null;
    _progreso = 0;
    _cambiar(EstadoModeloIA.descargando);
    _cancelToken = CancelToken();

    try {
      await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
          .fromNetwork(
            urlModelo,
            token: (tokenHuggingFace == null || tokenHuggingFace.isEmpty)
                ? null
                : tokenHuggingFace,
          )
          .withCancelToken(_cancelToken!)
          .withProgress((porcentaje) {
            _progreso = porcentaje / 100;
            _cambiar(EstadoModeloIA.descargando);
          })
          .install();

      _urlInstalada = urlModelo;
      _progreso = 1;
      _cambiar(EstadoModeloIA.listo);
    } catch (fallo) {
      if (CancelToken.isCancel(fallo)) {
        _progreso = 0;
        _cambiar(EstadoModeloIA.sinInstalar);
        return;
      }
      _error = _explicarError(fallo);
      _cambiar(EstadoModeloIA.error);
    }
  }

  @override
  Future<void> cancelarDescarga() async {
    _cancelToken?.cancel('Descarga cancelada por la persona');
  }

  @override
  Future<void> eliminarModelo() async {
    final url = _urlInstalada;
    if (url != null) {
      await FlutterGemma.uninstallModel(nombreDeArchivoModelo(url));
    }
    _urlInstalada = null;
    _progreso = 0;
    _cambiar(EstadoModeloIA.sinInstalar);
  }

  void cerrar() => _controlador.close();

  /// Traduce los fallos más comunes a un mensaje que la persona entienda.
  String _explicarError(Object fallo) {
    final texto = fallo.toString();
    if (texto.contains('401') || texto.contains('403')) {
      return 'El servidor ha rechazado la descarga. Si el modelo es de '
          'Google (Gemma), revisa que hayas aceptado su licencia en Hugging '
          'Face y que el token pegado sea correcto.';
    }
    if (texto.contains('404')) {
      return 'No se ha encontrado el archivo en esa dirección. Revisa el '
          'enlace de descarga.';
    }
    if (texto.contains('SocketException') ||
        texto.contains('Connection') ||
        texto.contains('Network')) {
      return 'No hay conexión de red disponible ahora mismo. La descarga '
          'inicial del modelo es lo único que necesita internet; una vez '
          'descargado, todo funciona sin conexión.';
    }
    return 'No se ha podido completar la descarga. $texto';
  }
}
