/// Paso 2 del onboarding: «Cuéntale a Vitalis sobre tu cuerpo».
/// Sección 3 · RF-02, RF-03, RF-04, RF-05.
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

class PasoCuerpo extends ConsumerWidget {
  const PasoCuerpo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final estado = ref.watch(estadoAppProvider);
    final notificador = ref.read(estadoAppProvider.notifier);
    final unidades = estado.preferencias.unidades;
    final metrico = unidades == Unidades.metrico;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Cuéntale a Vitalis sobre tu cuerpo',
            style: tema.textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: Espacio.s),
        Text(
          'Con el peso y la altura Vitalis calcula tu proteína del día. '
          'Podrás cambiarlos cuando quieras desde Perfil.',
          style: tema.textTheme.bodyMedium,
        ),
        const SizedBox(height: Espacio.xl),

        ControlSegmentado<Unidades>(
          etiquetaGrupo: 'Sistema de unidades',
          seleccionado: unidades,
          onElegir: notificador.cambiarUnidades,
          opciones: [
            for (final opcion in Unidades.values)
              OpcionSegmento(
                valor: opcion,
                etiqueta: '${opcion.etiqueta} · ${opcion.detalle}',
                nombreAccesible: 'Usar unidades en ${opcion.etiqueta.toLowerCase()}, '
                    '${opcion.detalle}',
              ),
          ],
        ),
        const SizedBox(height: Espacio.xl),

        AjustadorMedida(
          etiqueta: 'Peso',
          valor: metrico ? estado.perfil.pesoKg : kgALibras(estado.perfil.pesoKg),
          minimo: metrico ? pesoMinimoKg : kgALibras(pesoMinimoKg).roundToDouble(),
          maximo: metrico ? pesoMaximoKg : kgALibras(pesoMaximoKg).roundToDouble(),
          textoValor: textoPeso(estado.perfil.pesoKg, unidades),
          nombreUnidad: unidadPesoHablada(unidades),
          onCambiar: (valor) => notificador.cambiarPeso(
            metrico ? valor : librasAKg(valor),
          ),
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
          onCambiar: (valor) => notificador.cambiarAltura(
            metrico ? valor : pulgadasACm(valor),
          ),
        ),
        const SizedBox(height: Espacio.xl),

        const TarjetaImc(),
        const SizedBox(height: Espacio.xl),

        const TituloSeccion(
          '¿Qué buscas?',
          detalle: 'Vitalis ajusta la proteína y las rutinas a tu objetivo.',
        ),
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
                nombreAccesible: 'Objetivo: ${objetivo.etiqueta}. '
                    'Propone ${objetivo.tasaSugerida.gPorKg.toStringAsFixed(1)
                        .replaceAll('.', ',')} gramos de proteína por kilo.',
              ),
          ],
        ),
        const SizedBox(height: Espacio.xl),

        const TituloSeccion(
          '¿Necesitas alguna adaptación?',
          detalle: 'Puedes marcar varias. Cambian cómo se presenta el '
              'entrenamiento, nunca lo que puedes hacer.',
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
      ],
    );
  }
}
