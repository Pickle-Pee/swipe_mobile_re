# Repository guidance

## Scope

This repository contains the Flutter client for the Swipe demo application. Preserve the existing screen design unless a task explicitly requests UI changes.

## Tooling and checks

- Use the stable Flutter SDK compatible with the SDK constraint in `pubspec.yaml`.
- After dependency changes, run `flutter pub get` and commit `pubspec.lock` changes.
- Before finishing, run `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, and `flutter test`.
- For Android-related work, also run `flutter build apk --debug`.

## Environments

- Runtime configuration is centralized in `lib/core/config/config.dart`.
- Select `demo`, `development`, or `production` with `--dart-define=APP_ENV=...`.
- Configure endpoints only with `REST_API_URL` and `SOCKET_IO_URL`; do not hardcode service URLs in screens, repositories, or services.
- Configure demo behavior with `DEMO_MODE`. Production rejects local endpoints and demo mode.
- Do not commit credentials, signing material, tokens, `.env` files, or real personal data. Dart defines are configuration, not secret storage.

## Change discipline

- Keep changes small and scoped to the task.
- Do not silently change backend API contracts.
- Do not hide failures with empty catches or disable checks to make CI pass.
- Check `git diff` and `git status` before handoff.
