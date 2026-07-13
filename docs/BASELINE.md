# Flutter baseline

## Project structure

- `lib/app`: application root, router, providers, and tab shell.
- `lib/core`: shared configuration, networking, socket, events, and secure token storage.
- `lib/data`: models, repositories, and service abstractions.
- `lib/features`: onboarding, discovery, likes, chat, profile, settings, and subscription screens.
- `lib/shared`: shared theme and UI components.
- `assets/shaders`: visual shader assets.
- `test`: automated Flutter tests.

The application entry point is `lib/main.dart`. It starts a Riverpod `ProviderScope` and `App`, whose `GoRouter` initially opens onboarding.

## Toolchain snapshot

The project declares Dart SDK `^3.10.4`. Generated package metadata records Flutter `3.38.5` and Dart/pub `3.10.4` as the toolchain used for the last dependency resolution. At baseline creation, neither `flutter`, `dart`, nor `java` was available in the command environment, and the SDK path recorded in generated metadata no longer existed. The commands below therefore could not be rerun from that shell.

Android is configured for Java 17 bytecode and uses the Flutter-provided compile, target, NDK, and minimum SDK versions. The Gradle wrapper is 8.14.

## Dependencies

Dependencies are locked in `pubspec.lock`. The main integrations are Dio, Riverpod, GoRouter, secure storage, Socket.IO, MobX, and UUID. Run:

```powershell
flutter pub get
```

## Environment configuration

All environment values are defined in `lib/core/config/config.dart` and supplied at compile/run time with `--dart-define`:

| Define | Purpose | Default |
| --- | --- | --- |
| `APP_ENV` | `demo`, `development`, or `production` | `development` |
| `REST_API_URL` | REST API base URL | Android emulator host for demo/development |
| `SOCKET_IO_URL` | Socket.IO base URL | Android emulator host for demo/development |
| `DEMO_MODE` | Explicit `true`/`false` demo behavior | enabled only for demo |

Demo and development default to `http://10.0.2.2:1024` for REST and `http://10.0.2.2:1025` for Socket.IO. The `10.0.2.2` address reaches the host machine from an Android emulator. A physical device needs reachable LAN addresses. Production has no endpoint defaults: both URLs must be supplied, must be absolute HTTP(S) URLs, and must not use a known local host. Demo mode is rejected in production.

Dart defines are visible in the compiled application and must never contain secrets.

### Run examples

```powershell
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
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug --dart-define=APP_ENV=demo
```

CI runs dependency installation, formatting, analysis, and tests on pushes and pull requests. Android debug assembly remains a local/release check to keep the minimal CI focused on code quality.

## Baseline limitations

- The local shell used for this baseline had no accessible Flutter, Dart, or Java executable. `flutter pub get`, formatting, analysis, tests, and APK assembly still need verification in a configured Flutter environment. Existing generated metadata indicates that dependencies had previously been resolved with Flutter 3.38.5.
- Existing screens contain static demonstration data and unfinished provider/repository wiring; backend integration is outside this foundation task.
- Production backend hostnames are intentionally not invented. Supply buyer/deployment-specific URLs with Dart defines.
- Native application identifiers and release signing are still template defaults and require deployment-specific setup.
