# Vitalis — Documentación de desarrollo

Vitalis es una app móvil de fitness en casa, **privada** y **accesible por diseño**. Esta documentación se deriva del prototipo de Claude Design (`Vitalis Accessible Fitness.dc.html`, sistema visual *Nocturne*) y **no fija tecnologías**: describe qué debe hacer la app y por qué, no con qué se construye.

> El prototipo incluye código Jetpack Compose (`compose/*.kt`) y usa WebGL/Lottie. Aquí se tratan como **referencia de intención**, no como decisión. Las decisiones tecnológicas se registran en [08-decisiones-pendientes.md](08-decisiones-pendientes.md).

## Índice

| # | Documento | Contenido |
|---|-----------|-----------|
| 01 | [Visión y alcance](01-vision-alcance.md) | Propósito, usuarios, principios, alcance y fuera de alcance |
| 02 | [Requisitos](02-requisitos.md) | Funcionales y no funcionales, con identificadores trazables |
| 03 | [Pantallas y flujos](03-pantallas-flujos.md) | Mapa de navegación, especificación de cada pantalla, estados |
| 04 | [Reglas de negocio](04-reglas-negocio.md) | Fórmulas (IMC, proteína, reparto), rutinas, agua, asistente |
| 05 | [Modelo de datos](05-modelo-datos.md) | Entidades, relaciones, ciclo de vida, privacidad |
| 06 | [Accesibilidad](06-accesibilidad.md) | Perfiles, canales de señal, criterios de aceptación |
| 07 | [Sistema de diseño](07-sistema-diseno.md) | Tokens Nocturne, temas, componentes, reglas visuales |
| 08 | [Decisiones pendientes](08-decisiones-pendientes.md) | Arquitectura agnóstica, opciones tecnológicas, ADRs por abrir |
| 09 | [Calidad, pruebas y roadmap](09-calidad-roadmap.md) | Estrategia de pruebas, definición de hecho, fases, riesgos |
| 10 | [Glosario](10-glosario.md) | Términos del dominio |
| 11 | [Decisiones tomadas](11-decisiones-tomadas.md) | ADR cerrados en la implementación en Flutter y supuestos que siguen abiertos |

## Cómo usar estos documentos

- Los requisitos llevan ID (`RF-xx`, `RNF-xx`); las pruebas y tareas deben referenciarlos.
- Los valores marcados **(supuesto)** los asumió el prototipo y necesitan validación con producto/usuarios.
- Los valores marcados **(pendiente)** aparecen en el prototipo como trabajo futuro.
- Idioma de la interfaz: español (el código Compose del prototipo aún está en inglés; su traducción es un paso pendiente).
