# Vitalis

App móvil de fitness en casa, **privada** y **accesible por diseño**.
Implementación en Flutter de la [documentación de desarrollo](docs/README.md).

Todo ocurre en el dispositivo: sin cuenta, sin nube y sin analítica. Un
asistente conversacional con un **modelo de IA real empaquetado en la app**
(no descargado) es la puerta de entrada, con chat de voz completo —hablas,
te escucha, te responde y te lo dice en voz alta—, pero Dieta, Entreno y
Perfil siguen siendo accesibles directamente.

## Arrancar

```bash
flutter pub get
./scripts/descargar_modelo_ia.sh   # una sola vez: ~520 MB, ver docs/12
flutter run                         # Android o iOS
flutter test                        # 112 pruebas
dart analyze                        # sin avisos
```

Requiere Flutter 3.47 o superior (Dart 3.13). El modelo de IA **no** está en
el repositorio (pesa más que el límite de GitHub); el script lo descarga una
única vez, antes de compilar — ver
[docs/12-modelo-ia-local.md](docs/12-modelo-ia-local.md). Sin ese paso,
`flutter build`/`flutter run` fallan señalando el asset que falta.

## Cómo está organizado

Las capas son las de la [sección 8](docs/08-decisiones-pendientes.md) de la
documentación. **El dominio no depende de la interfaz ni de los servicios**;
los servicios se inyectan detrás de contratos para poder simularlos.

```
lib/
  dominio/            Lógica pura: IMC, proteína, plan, agua, cronómetro,
    modelos/          intenciones. Sin E/S, sin Flutter salvo tipos básicos.
    logica/
    catalogo/         Platos y rutinas.
  servicios/
    contratos/        Almacen · Voz · SintesisVoz · Haptico · Anunciador ·
                       MotorIA · ConversadorIA · GestorModeloIA · Reloj
    impl/             Implementaciones reales, sustituibles una a una.
                       motor_ia_hibrido.dart: reglas para lo estructurado
                       (plan/agua/entreno, nunca inventadas) + el modelo real
                       para la conversación libre.
  estado/             Una sola fuente de verdad (Riverpod) + notificadores.
  core/               Tokens y temas de Nocturne.
  ui/                 Onboarding · Inicio · Dieta · Entreno · Reproductor · Perfil
assets/
  modelo_ia/          Modelo de IA local (.gitignore; ver scripts/).
test/
  dominio/            61 pruebas de lógica pura, con reloj simulado.
  estado/             34 pruebas de estado, reproductor, IA híbrida y chat de voz.
  ui/                 17 pruebas de flujos y de accesibilidad.
  dobles/             Dobles de los nueve contratos.
```

El **reproductor es una capa, no una pestaña**: mientras se entrena, la
navegación queda fuera de alcance también para el lector de pantalla y el
teclado, no solo tapada.

## Privacidad

- El modelo de IA local viene **empaquetado en la app** (ADR-03) y se
  instala desde ahí al arrancar: cero peticiones de red en el uso normal.
  Ver [docs/12-modelo-ia-local.md](docs/12-modelo-ia-local.md).
- El permiso `INTERNET` existe por una única vía avanzada y opt-in en
  Perfil → «IA local» → «Usar otro modelo», para quien quiera sustituir el
  modelo empaquetado por otro descargado por URL. Es el único punto de toda
  la app donde se usa la red.
- El micrófono es para el dictado, forzado a reconocimiento **en el
  dispositivo**. La voz de salida usa el motor de TTS del sistema, también
  offline.
- La tipografía Inter va empaquetada en `assets/fuentes/`; descargarla en
  tiempo de ejecución rompería el requisito de funcionar sin conexión.
- «Exportar mis datos» genera un JSON legible que se muestra y se copia al
  portapapeles. «Borrar mis datos» deja la app como recién instalada.

## Accesibilidad

Las adaptaciones **cambian cómo se presenta el entrenamiento, nunca qué se
puede hacer**, y se acumulan. Cada señal tiene al menos dos canales.

Las pruebas de `test/ui/accesibilidad_test.dart` comprueban con las guías
oficiales de Flutter que en las cuatro pestañas y en los dos temas se cumplen
`androidTapTargetGuideline`, `iOSTapTargetGuideline`,
`labeledTapTargetGuideline` y `textContrastGuideline`, e incluyen el caso
**«ambas necesidades»** (subtítulos + vibración a la vez) que la
documentación dejaba pendiente de probar.

Lo que las pruebas automáticas **no** sustituyen, y sigue pendiente:
probar con TalkBack y VoiceOver reales, con escalado de fuente máximo, sin
sonido, sin vibración y con usuarios de cada perfil.

## Decisiones

Los ADR que la documentación dejaba abiertos se cerraron en
[docs/11-decisiones-tomadas.md](docs/11-decisiones-tomadas.md), incluido el
«punto por aclarar» del Anexo A sobre objetivo y tasa de proteína.
