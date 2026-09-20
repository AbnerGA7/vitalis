# 12 — Modelo de IA local: integrado, no descargado

Ampliación de [ADR-03](11-decisiones-tomadas.md) tras una decisión explícita
del encargo: el asistente debe tener un modelo de lenguaje real, con voz de
entrada y salida, y **funcionar al 100 % sin conexión desde el instante en
que se instala la app**, no desde que alguien pulsa «descargar».

## Qué se integró y por qué

| Pieza | Elección | Motivo |
|-------|----------|--------|
| Motor de inferencia | `flutter_gemma` + `flutter_gemma_mediapipe` | Corre modelos `.task` en el dispositivo; funciona en `arm64-v8a` y también en `x86_64` (a diferencia del backend `.litertlm`, solo `arm64`), lo que cubre más gama de móviles |
| Modelo | **Qwen2.5-0.5B-Instruct** (`litert-community`, cuantizado `q8`, ~520 MB) | Apache-2.0, **sin licencia gateada**: se puede empaquetar y redistribuir directamente. Multilingüe con soporte de español razonable a su tamaño. Los modelos Gemma de Google exigen aceptar su licencia con una cuenta de Hugging Face y no se pueden redistribuir así |
| Entrada de voz | `speech_to_text`, ya existente (RF-10, RF-11) | Reconocimiento forzado a `onDevice: true` |
| Salida de voz | `flutter_tts` | Motor de voz del sistema, offline en Android e iOS |

El resultado es un **chat de voz** completo: se pulsa el micro, se dicta, al
terminar se envía solo, el modelo responde y la respuesta se lee en voz alta,
sin ningún paso manual de por medio.

## Por qué el modelo no vive en el repositorio de Git

Los 520 MB del modelo superan el límite de GitHub para un archivo en un
commit normal (100 MB), y Git LFS en el plan gratuito solo da 1 GB de
almacenamiento y 1 GB de ancho de banda al mes — un solo `git clone` podría
agotar la cuota.

En vez de eso:

- El fichero vive en `assets/modelo_ia/` y está en `.gitignore`.
- `scripts/descargar_modelo_ia.sh` lo descarga una vez, antes de compilar
  (documentado en el README como primer paso de configuración).
- `pubspec.yaml` declara la ruta como asset: si el fichero no está presente,
  `flutter pub get`/`flutter build` fallan con un error claro señalando la
  ruta que falta.

Esto es un requisito **de quien compila la app**, no de quien la usa: la
persona que instala el `.apk` ya terminado nunca necesita red para nada
relacionado con el modelo.

## Qué pasa en el teléfono, paso a paso

1. Al arrancar, `main()` llama a `GestorModeloGemma.instalarModeloEmpaquetado()`
   sin esperar a que termine, para no retrasar la primera pantalla.
2. `flutter_gemma` instala el modelo **desde el asset empaquetado**
   (`fromAsset(...)`) — ninguna petición de red.
3. Mientras se instala (unos segundos), el asistente sigue resolviendo plan,
   agua y entreno por reglas, como si no hubiera modelo.
4. En cuanto queda listo, `MotorIAHibrido.conversacionDisponible` pasa a
   `true` y la conversación libre empieza a pasar por el modelo real, sin que
   la persona tenga que hacer nada.

## La única excepción de red que queda

Perfil → «IA local» → «Usar otro modelo» sigue permitiendo **cambiar** el
modelo empaquetado por otro descargado por URL (por ejemplo, un Gemma más
grande si la persona tiene su propio token de Hugging Face). Es la única
pantalla de toda la app donde se declara el permiso `INTERNET`, y solo se usa
si la persona pulsa ese botón explícitamente.

## Trade-offs asumidos

- **Calidad conversacional**: 0,5 mil millones de parámetros es un modelo
  pequeño. Responde bien a peticiones cortas y recomendaciones sencillas;
  no es comparable a un modelo de varios miles de millones de parámetros ni a
  un servicio en la nube. Es el trade-off explícito entre «cabe en la app
  desde el primer instante» y «la mejor calidad posible».
- **Tamaño de la app**: el `.apk` resultante pesa varios cientos de MB más
  que sin el modelo. Es el coste directo de que funcione sin descarga.
- **`arm64-v8a` recomendado**: MediaPipe también corre en `x86_64`, pero el
  rendimiento y la disponibilidad de aceleración por GPU son mejores en
  `arm64-v8a`, que es lo que trae la inmensa mayoría de los móviles reales.

## Cambiar de modelo

Para usar otro modelo empaquetado (más grande, más pequeño, otro idioma):

1. Sustituir el fichero en `assets/modelo_ia/` y actualizar la ruta en
   `rutaModeloEmpaquetado` (`lib/servicios/impl/gestor_modelo_gemma.dart`) y
   en `pubspec.yaml`.
2. Revisar el `ModelType` correcto en `instalarModeloEmpaquetado()` (Qwen,
   Gemma, DeepSeek… cada familia tiene el suyo).
3. Confirmar que el modelo elegido tiene licencia redistribuible si se va a
   empaquetar en el repositorio de assets de un equipo; si no, dejarlo como
   descarga por URL desde la pantalla «Usar otro modelo».
