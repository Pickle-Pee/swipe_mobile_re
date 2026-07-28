# Flutter baseline

# Flutter baseline

Актуально после DES-08, 2026-07-27. Подробная схема и правила расширения:
`docs/architecture/CANONICAL_UI_ARCHITECTURE.md`.

## Project structure

- `lib/app`: composition root, one GoRouter/AppGate, and one indexed tab shell.
- `lib/core`: environment configuration and the shared safe API client.
- `lib/features`: auth, onboarding, discovery, likes, match, chat, profile,
  settings, and subscription vertical slices.
- `lib/shared`: semantic Midnight Aura theme, media, and reusable UI.
- `test`: automated Flutter tests.

The application entry point is `lib/main.dart`. It starts a Riverpod
`ProviderScope` and `App`; GoRouter opens `/bootstrap`, and `AppGate` resolves
the signed-out, onboarding, or ready destination.

## Toolchain snapshot

The project declares Dart SDK `^3.10.4`. The DES-08 local verification uses
Flutter 3.44.6 stable and Dart 3.12.2.

Android is configured for Java 17 bytecode and uses the Flutter-provided compile, target, NDK, and minimum SDK versions. The Gradle wrapper is 8.14.

## Dependencies

Dependencies are locked in `pubspec.lock`. Runtime dependencies are Dio,
Riverpod, GoRouter, secure storage, Socket.IO, image picker, URL launcher,
collection and UUID. MobX and its generated legacy stores were removed.

```powershell
flutter pub get
```

## Environment configuration

All environment values are defined in `lib/core/config/config.dart` and supplied at compile/run time with `--dart-define`:

| Define | Purpose | Default |
| --- | --- | --- |
| `APP_ENV` | `demo`, `development`, or `production` | `demo` for debug/profile; `production` for release |
| `REST_API_URL` | REST API base URL | Android emulator host for demo/development |
| `SOCKET_IO_URL` | Socket.IO base URL | Android emulator host for demo/development |
| `DEMO_MODE` | Explicit `true`/`false` demo behavior | enabled only for demo |

Debug and profile builds select `demo` when `APP_ENV` is omitted. Demo and
development default to `http://10.0.2.2:1024` for REST and
`http://10.0.2.2:1025` for Socket.IO. The `10.0.2.2` address reaches the host
machine from an Android emulator. A physical device needs reachable LAN
addresses. Release builds default to `production` and fail closed unless both
production URLs are supplied; production also rejects known local hosts and
demo mode.

With the local backend Compose stack running, the seeded fictional account is
`70000000001`; the backend returns demo verification code `000000`. The phone
screen exposes a **Use demo account** shortcut. These are public local demo
values, not credentials or personal data.

Dart defines are visible in the compiled application and must never contain secrets.

### Run examples

```powershell
# Safe default for a debug/profile build on Android Emulator.
flutter run

flutter run --dart-define=APP_ENV=demo

flutter run `
  --dart-define=APP_ENV=development `
  --dart-define=REST_API_URL=http://10.0.2.2:1024 `
  --dart-define=SOCKET_IO_URL=http://10.0.2.2:1025

flutter run `
  --dart-define=APP_ENV=production `
  --dart-define=REST_API_URL=https://api.your-domain.example `
  --dart-define=SOCKET_IO_URL=https://socket.your-domain.example `
  --dart-define=DEMO_MODE=false
```

## Checks and builds

Run the baseline checks from the repository root:

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

CI runs dependency installation, formatting, analysis, and tests on pushes and pull requests. Android debug assembly remains a local/release check to keep the minimal CI focused on code quality.

## Baseline limitations

- Production backend hostnames are intentionally not invented. Supply
  buyer/deployment-specific HTTPS URLs with Dart defines.
- App links, automatic recurrent Charge, billing history/refunds UI and store
  billing are outside the current product stage.
- Native application identifiers, legal/support destinations and release
  signing still require buyer/deployment-specific setup.
- Demo content comes from the configured backend demo mode; the production
  screen layer does not contain static profiles or message history.
