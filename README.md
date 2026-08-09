# CEOSMOS - Ecosistema Dispositivos Inteligentes

## Estructura del proyecto
El proyecto está compuesto por 3 aplicaciones independientes, cada una con su propio código, dependencias y build:
- `movil/` — App móvil (Flutter)
- `wearable/` — App wearable (Flutter)
- `tv/` — App TV (PWA estática: HTML/CSS/JS + Firebase)

## Topología de despliegue para la demo
- **App móvil (`movil/`) y app wearable (`wearable/`)**: ambas se instalan en el mismo dispositivo Android (tablet), comunicándose entre sí vía BLE (móvil = central, wearable = peripheral).
- **App TV (`tv/`)**: PWA servida localmente y abierta en el navegador de la laptop, en modo emulación de TV 1920x1080 vía Chrome DevTools.
- **Las 3 aplicaciones son independientes entre sí** (3 proyectos separados, 3 builds distintos), aunque dos de ellas compartan el mismo dispositivo físico.

## Cómo ejecutar cada app

### App móvil
```bash
cd movil
flutter pub get
flutter build apk --debug
```
Instalar el APK generado en `build/app/outputs/flutter-apk/` en el dispositivo Android.
**Requiere**: `movil/android/app/google-services.json` (copiar desde Firebase Console, ver `google-services.json.example` para el formato esperado).

### App wearable
```bash
cd wearable
flutter pub get
flutter build apk --debug
```
Instalar en el mismo dispositivo Android que la app móvil, o en uno separado.

### App TV
Servir con un servidor estático local, ej:
```bash
cd tv
python -m http.server 8080
```
Abrir `http://localhost:8080` en el navegador.
**Requiere**: `tv/js/firebase-config.js` (copiar desde `tv/js/firebase-config.example.js` con credenciales reales de la app web de Firebase).
**Para la demo**: usar Chrome DevTools > Toggle device toolbar > Responsive > 1920x1080.

## Configuración de Firebase
Las 3 apps comparten el mismo proyecto de Firebase, colecciones `contenidos` y `sesiones/activa` en Firestore.