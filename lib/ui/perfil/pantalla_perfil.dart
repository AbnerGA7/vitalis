/// Perfil: medidas, unidades, tema, objetivo, adaptaciones y privacidad.
/// Sección 3 · RF-50, RF-51, RF-52.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nocturne_tokens.dart';
import '../../dominio/logica/unidades.dart';
import '../../dominio/modelos/enums.dart';
import '../../dominio/modelos/perfil.dart';
import '../../estado/notificador_app.dart';
import '../widgets/componentes.dart';
import '../widgets/controles.dart';
import '../widgets/formato.dart';
import '../widgets/medidor.dart';
import '../widgets/tarjeta_imc.dart';
import 'bloque_ia_local.dart';
import 'bloque_privacidad.dart';

class PantallaPerfil extends ConsumerWidget {
  const PantallaPerfil({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(estadoAppProvider);
    final notificador = ref.read(estadoAppProvider.notifier);
    final unidades = estado.preferencias.unidades;
    final metrico = unidades == Unidades.metrico;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(Espacio.l),
        children: [
          const TituloSeccion(
            'Perfil',
            detalle: 'Cambia lo que necesites cuando quieras. No hace falta '
                'repetir los pasos del principio.',
          ),
          const SizedBox(height: Espacio.xl),

          const TituloSeccion('Tus medidas'),
          const SizedBox(height: Espacio.m),
          AjustadorMedida(
            etiqueta: 'Peso',
            valor:
                metrico ? estado.perfil.pesoKg : kgALibras(estado.perfil.pesoKg),
            minimo:
                metrico ? pesoMinimoKg : kgALibras(pesoMinimoKg).roundToDouble(),
            maximo:
                metrico ? pesoMaximoKg : kgALibras(pesoMaximoKg).roundToDouble(),
            textoValor: textoPeso(estado.perfil.pesoKg, unidades),
            nombreUnidad: unidadPesoHablada(unidades),
            onCambiar: (valor) =>
                notificador.cambiarPeso(metrico ? valor : librasAKg(valor)),
          ),
          const SizedBox(height: Espacio.l),
          AjustadorMedida(
            etiqueta: 'Altura',
            valor: metrico
                ? estado.perfil.alturaCm
                : cmAPulgadas(estado.perfil.alturaCm),
            minimo: metrico
                ? alturaMinimaCm
                : cmAPulgadas(alturaMinimaCm).roundToDouble(),
            maximo: metrico
                ? alturaMaximaCm
                : cmAPulgadas(alturaMaximaCm).roundToDouble(),
            textoValor: textoAltura(estado.perfil.alturaCm, unidades),
            nombreUnidad: unidadAlturaHablada(unidades),
            onCambiar: (valor) =>
                notificador.cambiarAltura(metrico ? valor : pulgadasACm(valor)),
          ),
          const SizedBox(height: Espacio.l),
          const TarjetaImc(),
          const SizedBox(height: Espacio.m),
          const _ImpactoEnProteina(),
          const SizedBox(height: Espacio.xl),

          const TituloSeccion('Unidades'),
          const SizedBox(height: Espacio.m),
          ControlSegmentado<Unidades>(
            etiquetaGrupo: 'Sistema de unidades',
            seleccionado: unidades,
            onElegir: notificador.cambiarUnidades,
            opciones: [
              for (final opcion in Unidades.values)
                OpcionSegmento(
                  valor: opcion,
                  etiqueta: '${opcion.etiqueta} · ${opcion.detalle}',
                  nombreAccesible: 'Usar unidades en '
                      '${opcion.etiqueta.toLowerCase()}, ${opcion.detalle}',
                ),
            ],
          ),
          const SizedBox(height: Espacio.xl),

          const TituloSeccion('Tema'),
          const SizedBox(height: Espacio.m),
          ControlSegmentado<TemaApp>(
            etiquetaGrupo: 'Tema visual',
            seleccionado: estado.preferencias.tema,
            onElegir: notificador.cambiarTema,
            opciones: [
              for (final tema in TemaApp.values)
                OpcionSegmento(
                  valor: tema,
                  etiqueta: tema.etiqueta,
                  nombreAccesible: 'Tema ${tema.etiqueta.toLowerCase()}',
                ),
            ],
          ),
          const SizedBox(height: Espacio.xl),

          const TituloSeccion('Objetivo'),
          const SizedBox(height: Espacio.m),
          ControlSegmentado<Objetivo>(
            etiquetaGrupo: 'Objetivo',
            seleccionado: estado.perfil.objetivo,
            onElegir: notificador.cambiarObjetivo,
            opciones: [
              for (final objetivo in Objetivo.values)
                OpcionSegmento(
                  valor: objetivo,
                  etiqueta: objetivo.etiqueta,
                  nombreAccesible: 'Objetivo: ${objetivo.etiqueta}',
                ),
            ],
          ),
          const SizedBox(height: Espacio.xl),

          const TituloSeccion(
            'Adaptaciones',
            detalle: 'Se editan aquí, sin repetir el onboarding. Se acumulan: '
                'puedes tener varias a la vez.',
          ),
          const SizedBox(height: Espacio.m),
          for (final necesidad in Necesidad.values) ...[
            CasillaNecesidad(
              titulo: necesidad.etiqueta,
              descripcion: necesidad.descripcion,
              marcada: estado.preferencias.necesidades.contains(necesidad),
              onCambiar: (_) => notificador.alternarNecesidad(necesidad),
            ),
            const SizedBox(height: Espacio.s),
          ],
          const SizedBox(height: Espacio.xl),

          const BloqueIALocal(),
          const SizedBox(height: Espacio.xl),

          const BloquePrivacidad(),
          const SizedBox(height: Espacio.xxl),
        ],
      ),
    );
  }
}

/// Cómo afecta el peso a la proteína (RF-51).
class _ImpactoEnProteina extends ConsumerWidget {
  const _ImpactoEnProteina();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final estado = ref.watch(estadoAppProvider);

    return TarjetaVitalis(
      resumenAccesible: 'Tu peso marca tu proteína: '
          '${estado.formula.replaceAll('×', 'por')}. '
          'Si cambias el peso, el plan de comidas se recalcula.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tu peso marca tu proteína', style: tema.textTheme.titleSmall),
          const SizedBox(height: Espacio.s),
          Text(estado.formula, style: tema.textTheme.bodyLarge),
          const SizedBox(height: Espacio.s),
          Text(
            'Si cambias el peso o la tasa, Vitalis te pedirá regenerar el plan '
            'para que cuadre.',
            style: tema.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
