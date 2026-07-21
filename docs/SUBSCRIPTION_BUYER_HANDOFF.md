# Flutter subscription buyer handoff

Актуально для Flutter commit `ba4edb0`, Subscription API v1 и backend handoff `swipe_api/docs/integrations/TBANK_BUYER_HANDOFF.md` на 2026-07-13.

## Ответственность Flutter

Клиент получает тарифы, выбирает tariff id, создаёт checkout через backend, открывает PaymentURL во внешнем браузере, проверяет backend status и отображает active subscription. Flutter не содержит TerminalKey/Password, не формирует банковский Token, не обращается к `/v2/Init` и не активирует подписку по redirect.

## Конфигурация сборки

Настройки задаются только через `--dart-define`:

| Define | Demo | Production |
|---|---|---|
| `APP_ENV` | `demo` | `production` |
| `DEMO_MODE` | `true` | `false` |
| `REST_API_URL` | URL demo backend | публичный HTTPS backend |
| `SOCKET_IO_URL` | URL demo Socket.IO | публичный HTTPS/WSS gateway |

Demo Android Emulator:

```powershell
flutter pub get
flutter run --dart-define=APP_ENV=demo --dart-define=DEMO_MODE=true --dart-define=REST_API_URL=http://10.0.2.2:1024 --dart-define=SOCKET_IO_URL=http://10.0.2.2:1025
```

Production APK example:

```powershell
flutter build apk --release --dart-define=APP_ENV=production --dart-define=DEMO_MODE=false --dart-define=REST_API_URL=https://api.example.com --dart-define=SOCKET_IO_URL=https://socket.example.com
```

Dart defines видны внутри приложения и не подходят для банковских или иных secrets. Production-конфигурация отклоняет localhost/127.0.0.1/`10.0.2.2` и включённый demo mode.

## Пользовательский путь

1. Открыть Premium и загрузить `GET /subscriptions` и `GET /subscriptions/active`.
2. Выбрать тариф, сформировать UUID idempotency key и отправить `POST /subscriptions/checkout` только с `subscription_id`.
3. Открыть HTTPS PaymentURL через external application.
4. После возвращения/foreground запросить `GET /subscriptions/payments/{order_id}`.
5. Pending/processing отображать как ожидание; ограничить polling и оставить ручную кнопку Check payment.
6. Только backend `succeeded` показывает подтверждение, обновляет active subscription и профиль.
7. `failed`, `canceled`, refund и timeout не дают локальный entitlement.
8. `POST /subscriptions/cancel` выключает renewal, но сохраняет отображаемый оплаченный `end_at`.

## Возврат из платёжной формы

Текущая реализация надёжно работает без app link: внешний браузер возвращает управление пользователю, а lifecycle `resumed` и кнопка Check payment запрашивают backend. SuccessURL/FailURL не являются доказательством результата.

Если покупатель позже добавляет app links:

1. Настроить HTTPS домен и Android `intent-filter`/Digital Asset Links.
2. Использовать один безопасный return route без банковских secrets в query.
3. По ссылке только найти локальный pending checkout и вызвать status endpoint.
4. Не принимать из link цену, user id, payment status или entitlement.
5. Добавить manifest/widget/integration tests и проверить cold start, background и установленный браузер.

Отсутствие app links не блокирует текущую оплату.

## UI-состояния

- plans: loading, data, empty, error/retry;
- checkout: creating, awaiting confirmation, checking;
- terminal: confirmed, failed, canceled, timed out;
- active subscription: тариф, дата окончания, renewal on/off;
- demo: явная маркировка и success/failure controls только при `DEMO_MODE=true`.

При сетевой ошибке пользователь может повторить status check. После перезапуска active subscription загружается с backend; незавершённый checkout сейчас не сохраняется локально между переустановками/очисткой данных.

## API и безопасность

Полный JSON-контракт находится в `docs/contracts/SUBSCRIPTION_API.md`. Backend OpenAPI остаётся источником истины.

- Не добавлять прямой T-Банк client в Flutter.
- Не логировать Authorization, access/refresh token, PaymentURL query или полные ответы оплаты.
- Не хранить PAN/CVV/ExpDate/RebillId/CardId.
- Не создавать WebView или собственную форму карты; используется банковская форма во внешнем приложении.
- Не считать цену из UI авторитетной и не отправлять её в checkout.
- REM-05 закрыла raw auth/refresh/profile/chat/likes/matches response logging. Shared `ApiClient` использует `SafeApiLogInterceptor`: только method, path без query, status, duration, safe error code и request id; headers и bodies не логируются, default sink отключён в release.
- REM-04 удалила неиспользуемые legacy network/service/MethodChannel классы и старые DTO после подтверждения отсутствия runtime-потребителей. Канонический клиент использует только shared `ApiClient`, Riverpod controller и server-priced `/subscriptions/checkout`.

## Проверки

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Последний SUB-05 прогон: 51 Flutter tests passed, subscription target analyze чист, debug APK собран. Полный analyze содержит 271 legacy issue вне subscription-модуля и пока не является зелёным release gate.

Ручная проверка:

1. Запустить backend demo и Flutter demo.
2. Проверить динамические тарифы и одну операцию при двойном нажатии.
3. Вернуться с PaymentURL: состояние не должно стать successful само.
4. Пройти Demo success и Demo failure.
5. Проверить offline → reconnect → Check payment.
6. Перезапустить приложение и проверить active subscription.
7. Отключить renewal и убедиться, что end date не изменилась.

## Ограничения

- Автоматические повторные списания и Charge не реализованы.
- Billing history и refunds UI не реализованы.
- App links не настроены; используется lifecycle/manual refresh.
- Реальная банковская test environment должна быть проверена покупателем вместе с backend и публичным HTTPS webhook.
- Release signing, store distribution и юридические тексты не входят в репозиторный demo scope.

## Готовность

Канонический Flutter subscription flow готов для demo. Backend scheduler/init blockers закрыты REM-01/REM-03, Flutter legacy payment flow удалён REM-04, а опасное Flutter auth/payment logging закрыто REM-05. Перед production покупатель должен предоставить production HTTPS endpoints, завершить банковский checklist, выполнить финальный secret scan и настроить Android release signing. Банковские secrets в мобильную сборку добавлять не требуется и запрещено.
