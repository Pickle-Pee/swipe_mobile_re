# Swipe Flutter client

Android-клиент Swipe. Конфигурация окружений задаётся через `--dart-define`; банковские secrets в мобильное приложение не передаются.

- Контракт подписок: `docs/contracts/SUBSCRIPTION_API.md`.
- Запуск demo, production build и buyer checklist: `docs/SUBSCRIPTION_BUYER_HANDOFF.md`.

## Локальный demo на Android Emulator

Обычные debug/profile сборки запускаются в `demo` без дополнительного
`--dart-define`. Запустите backend через Docker Compose, затем:

```powershell
flutter run
```

На экране телефона нажмите **Use demo account** или введите вымышленный номер
`70000000001`. Backend вернёт demo-код `000000`. Release-сборка по умолчанию
выбирает `production` и требует явные production REST/Socket.IO URL.
