# 11 — Decisiones tomadas en la implementación

Registro de los ADR que la [sección 8](08-decisiones-pendientes.md) dejaba
abiertos y que esta implementación ha tenido que cerrar para poder existir.
Cada uno dice **qué se decidió**, **por qué** y **qué haría falta para
cambiarlo**, porque ninguna es irreversible.

| ADR | Decisión | Por qué | Coste de cambiarla |
|-----|----------|---------|--------------------|
| ADR-01 | Android + iOS | Un solo código para las dos tiendas; el público objetivo no es solo Android | — |
| ADR-02 | Multiplataforma con **Flutter** | Decisión del encargo. Flutter expone `Semantics` con control fino sobre nombre, rol, estado y regiones vivas, que es lo que exige la sección 6 | Alto: reescritura |
| ADR-03 | Motor de IA local **por reglas y plantillas**, detrás de `MotorIA` | Funciona igual en gama baja, no gasta batería ni espacio, y en español no alucina. El contrato permite meter un modelo pequeño después sin tocar interfaz ni estado | Bajo: una implementación nueva del contrato |
| ADR-04 | Dictado del **servicio del sistema** con `onDevice: true` | El audio no sale del teléfono (RNF-01). Si el dispositivo no ofrece reconocimiento local, la app se queda solo con texto, que es la alternativa de AC-11 | Bajo: `Voz` es un contrato |
| ADR-05 | **Archivos JSON** sobre `SharedPreferences` | El volumen es diminuto (un perfil, un plan, un contador de agua, un historial corto) y no hay consultas que justifiquen una base de datos embebida | Medio: migración de datos |
| ADR-06 | Animaciones de técnica: **espacio reservado**, sin recurso todavía | El recurso no existe (pendiente del Anexo A). El hueco muestra la indicación escrita, que es lo que sostiene la información | Bajo |
| ADR-07 | Orbe con **`CustomPaint`**, no WebGL | Mucha menos batería en gama media y baja, y se detiene solo con «movimiento reducido» (RNF-05) | Bajo: es un widget aislado |
| ADR-08 | Exportación en **JSON** indentado | Legible a simple vista y reimportable. Se muestra en pantalla y se copia al portapapeles: no se envía a ningún sitio | Bajo |
| ADR-09 | Distribución: **tiendas** (sin decidir el calendario) | Fuera del alcance del código | — |
| ADR-10 | **Español** con los textos en el código de cada pantalla | v1 es monolingüe; `flutter_localizations` ya está cableado para cuando haya un segundo idioma (RNF-08) | Medio: extraer a ARB |

## El «punto por aclarar» del Anexo A

La documentación no definía cómo se relacionan los tres objetivos
(Perder peso · Ganar fuerza · Mantener movilidad) con las tres tasas de
proteína (Mantener 1,2 · Fuerza 1,6 · Recomposición 2,0).

**Resuelto así:** la tasa se **deriva** del objetivo al elegirlo, y sigue
siendo **editable a mano** en Dieta.

| Objetivo (RF-04) | Tasa propuesta (RF-20) |
|------------------|------------------------|
| Perder peso | Recomposición · 2,0 g/kg |
| Ganar fuerza | Fuerza · 1,6 g/kg |
| Mantener movilidad | Mantener · 1,2 g/kg |

Esto satisface las dos lecturas posibles: quien no quiera pensar en gramos
elige solo objetivo, y quien sepa lo que hace ajusta la tasa sin perder su
objetivo. En el modelo de datos son dos campos de `Perfil`
(`objetivo` y `tasaProteina`), no uno derivado, para que la elección manual
persista.

> Si producto decide lo contrario (una sola escala), el cambio está en
> `Objetivo.tasaSugerida` y en quitar el selector de tasa de Dieta.

## Supuestos que siguen siendo supuestos

Se han implementado con el valor que proponía el prototipo, y están marcados
en el código:

- Meta diaria de agua **2.500 ml**, tope de registro **3.000 ml**
  (`lib/dominio/logica/hidratacion.dart`).
- Rangos plausibles: peso **30–250 kg**, altura **100–230 cm**
  (`lib/dominio/modelos/perfil.dart`). La documentación no los fijaba.
- **5 sesiones por semana** como referencia del resumen semanal
  (`lib/ui/entreno/resumen_semanal.dart`).
- **Un perfil por dispositivo**.

## Lo que sigue pendiente

Nada de esto se ha implementado, tal y como marca el alcance de v1:

- Sustituir una comida sin regenerar el plan.
- Avisos por alergias.
- Historial semanal más allá del resumen de la semana en curso.
- Bucles de animación reales por ejercicio (ADR-06).
- Varios perfiles por dispositivo.
