/// Configuración del modelo de IA local real. ADR-03.
///
/// El modelo viene empaquetado en la app y se instala solo al arrancar, sin
/// red: el asistente conversa libremente desde el primer uso, sin pedirle
/// nada a la persona. Esta pantalla es para la vía avanzada: cambiar por otro
/// modelo distinto (más grande, otro idioma…), que sí exige descargarlo por
/// URL. Es el único caso en el que Vitalis usa la red.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nocturne_tema.dart';
import '../../core/nocturne_tokens.dart';
import '../../estado/notificador_app.dart';
import '../../estado/proveedores.dart';
import '../../servicios/contratos/contratos.dart';
import '../../servicios/impl/gestor_modelo_gemma.dart' show nombreDeArchivoModelo;
import '../widgets/componentes.dart';

/// Enlace de ejemplo: Gemma 3 1B en formato `.task`, el modelo con el que se
/// ha probado esta pantalla. Requiere aceptar la licencia de Gemma en
/// Hugging Face y pegar un token de acceso de esa cuenta.
const String urlModeloSugerida =
    'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/'
    'Gemma3-1B-IT_multi-prefill-seq_q8_ekv1280.task';

class BloqueIALocal extends ConsumerStatefulWidget {
  const BloqueIALocal({super.key});

  @override
  ConsumerState<BloqueIALocal> createState() => _BloqueIALocalState();
}

class _BloqueIALocalState extends ConsumerState<BloqueIALocal> {
  final TextEditingController _url = TextEditingController(
    text: urlModeloSugerida,
  );
  final TextEditingController _token = TextEditingController();
  bool _mostrarToken = false;

  /// Solo relevante cuando ya hay un modelo listo: alterna el formulario
  /// para cambiarlo por otro, que si no queda oculto.
  bool _cambiandoDeModelo = false;

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _descargar() async {
    final url = _url.text.trim();
    if (url.isEmpty) return;
    final gestor = ref.read(gestorModeloIAProvider);
    await gestor.descargar(
      urlModelo: url,
      tokenHuggingFace: _token.text.trim().isEmpty ? null : _token.text.trim(),
    );
    if (gestor.estado == EstadoModeloIA.listo) {
      await ref.read(estadoAppProvider.notifier).recordarModeloIA(url);
      if (mounted) setState(() => _cambiandoDeModelo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final paleta = context.paleta;
    final gestor = ref.watch(gestorModeloIAProvider);

    // El gestor no es un StateNotifier: se refresca con su propio stream.
    ref.watch(_estadoModeloProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TituloSeccion(
          'IA local',
          detalle: 'El modelo viene incluido en la app: no hace falta '
              'descargar nada para que el asistente converse contigo. Aquí '
              'puedes ver su estado o, si quieres, cambiarlo por otro.',
        ),
        const SizedBox(height: Espacio.m),
        TarjetaVitalis(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Estado(gestor: gestor),
              if (gestor.estado == EstadoModeloIA.sinInstalar ||
                  gestor.estado == EstadoModeloIA.error ||
                  _cambiandoDeModelo) ...[
                const SizedBox(height: Espacio.l),
                Text(
                  'Usar un modelo distinto del que trae la app requiere '
                  'conexión una sola vez, para descargarlo. Después, todo '
                  'vuelve a funcionar sin internet (RNF-01).',
                  style: tema.textTheme.bodySmall,
                ),
                const SizedBox(height: Espacio.m),
                TextField(
                  controller: _url,
                  decoration: const InputDecoration(
                    labelText: 'Enlace de descarga del modelo (.task)',
                    hintText: 'https://huggingface.co/…/modelo.task',
                  ),
                ),
                const SizedBox(height: Espacio.m),
                TextField(
                  controller: _token,
                  obscureText: !_mostrarToken,
                  decoration: InputDecoration(
                    labelText: 'Token de Hugging Face (si el modelo lo pide)',
                    suffixIcon: IconButton(
                      tooltip: _mostrarToken
                          ? 'Ocultar el token'
                          : 'Mostrar el token',
                      icon: Icon(
                        _mostrarToken
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _mostrarToken = !_mostrarToken),
                    ),
                  ),
                ),
                const SizedBox(height: Espacio.s),
                Text(
                  'Los modelos Gemma exigen aceptar su licencia en Hugging '
                  'Face antes de poder descargarlos con tu token.',
                  style: tema.textTheme.bodySmall
                      ?.copyWith(color: paleta.textoSuave),
                ),
                const SizedBox(height: Espacio.l),
                BotonVitalis(
                  texto: 'Descargar este modelo',
                  nombreAccesible: 'Descargar este modelo de IA local',
                  ocuparAncho: true,
                  onPressed: _descargar,
                ),
              ],
              if (gestor.estado == EstadoModeloIA.descargando) ...[
                const SizedBox(height: Espacio.l),
                ClipRRect(
                  borderRadius: BorderRadius.circular(radioPildora),
                  child: LinearProgressIndicator(
                    value: gestor.progreso,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: Espacio.s),
                Text(
                  '${(gestor.progreso * 100).round()} %',
                  style: tema.textTheme.bodySmall,
                ),
                const SizedBox(height: Espacio.m),
                BotonVitalis(
                  texto: 'Cancelar descarga',
                  nombreAccesible: 'Cancelar la descarga del modelo',
                  onPressed: () => gestor.cancelarDescarga(),
                ),
              ],
              if (gestor.estado == EstadoModeloIA.listo &&
                  !_cambiandoDeModelo) ...[
                const SizedBox(height: Espacio.l),
                BotonVitalis(
                  texto: 'Usar otro modelo',
                  nombreAccesible: 'Cambiar el modelo de IA local por otro',
                  onPressed: () => setState(() => _cambiandoDeModelo = true),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Texto del estado «listo», con el nombre de archivo del modelo activo
/// cuando se conoce (RF-52: la persona puede confirmar qué modelo cambió).
String _textoModeloListo(String? modeloInstalado) {
  if (modeloInstalado == null) {
    return 'Modelo listo. El asistente puede conversar libremente.';
  }
  final nombre = nombreDeArchivoModelo(modeloInstalado);
  return 'Modelo listo: $nombre. El asistente puede conversar libremente.';
}

class _Estado extends StatelessWidget {
  const _Estado({required this.gestor});

  final GestorModeloIA gestor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final paleta = context.paleta;

    final (icono, texto, color) = switch (gestor.estado) {
      EstadoModeloIA.sinInstalar => (
          Icons.smart_toy_outlined,
          'No hay ningún modelo descargado. El asistente usa reglas.',
          paleta.textoSuave,
        ),
      EstadoModeloIA.descargando => (
          Icons.downloading,
          'Descargando el modelo…',
          paleta.acento,
        ),
      EstadoModeloIA.listo => (
          Icons.check_circle_outline,
          _textoModeloListo(gestor.modeloInstalado),
          verdeTrabajo,
        ),
      EstadoModeloIA.error => (
          Icons.error_outline,
          gestor.error ?? 'La descarga ha fallado.',
          tema.colorScheme.error,
        ),
    };

    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: color),
          const SizedBox(width: Espacio.m),
          Expanded(
            child: Text(texto, style: tema.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Refresca la pantalla cuando cambia el estado del gestor (descarga en
/// curso, progreso, fin). El gestor no es un Notifier de Riverpod porque su
/// contrato ([GestorModeloIA]) es agnóstico del gestor de estado elegido.
final _estadoModeloProvider = StreamProvider((ref) {
  return ref.watch(gestorModeloIAProvider).cambiosDeEstado;
});
