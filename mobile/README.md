# Flutter — Móvil + Web completa

Cliente Flutter multi-plataforma para el Sistema Transporte B–M.

| Plataforma | Alcance |
|------------|---------|
| **Android / iOS** | **Solo consulta pública** (pasajeros: horarios, cupos, mapa de asientos). Sin login, cajero ni admin. |
| **Web** (`flutter run -d chrome`) | App completa: consulta, cajero, admin — **equivalente a `frontend/` React** |

La versión **React** en `frontend/` **no se elimina**; ambas web conviven.

> **Personal (cajero/admin):** use Flutter Web (`.\scripts\flutter-web.ps1`) o React (`npm run dev`), no la app Android.

## Requisitos

- Flutter SDK ≥ 3.11
- Backend Spring Boot (`8080`) + Keycloak (`8180`) para login y paneles operativos

## Arranque web (recomendado)

```powershell
.\scripts\flutter-web.ps1
```

→ http://127.0.0.1:5050

Documentación detallada: [docs/FLUTTER-WEB.md](../docs/FLUTTER-WEB.md)

### Modo demo (sin backend ni Keycloak)

Equivalente a `VITE_USE_MOCK=true` en React:

```powershell
.\scripts\flutter-web-demo.ps1
```

Build estático para hosting:

```powershell
cd mobile
flutter build web --dart-define=USE_MOCK=true --no-web-resources-cdn
```

## Arranque Android (emulador)

```powershell
.\scripts\flutter-android.ps1
```

Usa `http://10.0.2.2:8080` por defecto.

### Android Studio — error "No Windows desktop project"

Si al dar Run aparece `--device-id=windows` y falla, **no está corriendo Android**: eligió **Windows desktop** (este proyecto no tiene carpeta `windows/`).

1. **Device Manager** → inicie un emulador (debe verse arriba, ej. `sdk gphone64`).
2. En la barra superior, abra el desplegable de dispositivos y elija el **emulador Android**, no `Windows` ni `Chrome`.
3. Run configuration: **main.dart (Android)** (incluye `--dart-define=API_BASE=http://10.0.2.2:8080`).
4. La app abre **directo en consulta pública** (sin landing de admin/cajero).
5. Terminal alternativa (con emulador encendido):

```powershell
cd mobile
flutter run -d emulator-5554 --dart-define=API_BASE=http://10.0.2.2:8080
```

(`flutter devices` muestra el id exacto del emulador.)

Tras cambios de código (ej. formato AM/PM), use **Stop** y Run de nuevo, o `R` en la terminal (hot restart).

## Estructura modular

```
lib/
├── core/           # API, auth, models, router, theme
├── features/       # auth, consulta, cajero, admin
├── shared/         # OperativeShell, widgets
└── app.dart        # Entry con go_router
```

## Credenciales demo

`admin.global`, `admin.wendelyn`, `cajero.wendelyn` / `password`

## Tests

```powershell
cd mobile
flutter pub get
flutter analyze lib
flutter test
```

## React vs Flutter Web

| | React | Flutter Web |
|--|-------|-------------|
| Carpeta | `frontend/` | `mobile/` |
| Puerto | 5173 | 5050 |
| UI | MUI | Material 3 + sidebar teal |
