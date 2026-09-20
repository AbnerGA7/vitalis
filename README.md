# Vitalis

App móvil de fitness en casa, **privada** y **accesible por diseño**.
Implementación en Flutter de la [documentación de desarrollo](docs/README.md).

Todo ocurre en el dispositivo: sin cuenta, sin nube y sin analítica. Un
asistente de IA local, por voz y texto, es la puerta de entrada, pero Dieta,
Entreno y Perfil siguen siendo accesibles directamente.

## Arrancar

```bash
flutter pub get
flutter run           # Android o iOS
flutter test          # 88 pruebas
dart analyze          # sin avisos
```

Requiere Flutter 3.47 o superior (Dart 3.13).

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
    contratos/        Almacen · Voz · Haptico · Anunciador · MotorIA · Reloj
    impl/             Implementaciones reales, sustituibles una a una.
  estado/             Una sola fuente de verdad (Riverpod) + notificadores.
  core/               Tokens y temas de Nocturne.
  ui/                 Onboarding · Inicio · Dieta · Entreno · Reproductor · Perfil
test/
  dominio/            58 pruebas de lógica pura, con reloj simulado.
  estado/             17 pruebas de estado y del reproductor.
  ui/                 13 pruebas de flujos y de accesibilidad.
  dobles/             Dobles de los seis contratos.
```

El **reproductor es una capa, no una pestaña**: mientras se entrena, la
navegación queda fuera de alcance también para el lector de pantalla y el
teclado, no solo tapada.

## Privacidad

- No se declara permiso de red: la app no usa internet.
- El único permiso que pide es el **micrófono**, y solo para el dictado, que
  se fuerza a reconocimiento **en el dispositivo**.
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
