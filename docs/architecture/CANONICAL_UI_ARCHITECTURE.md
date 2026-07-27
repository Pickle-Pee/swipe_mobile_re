# Canonical Flutter UI architecture

Актуально после DES-08, 2026-07-27. Этот документ описывает единственный
production path Flutter-клиента после удаления legacy UI и архитектурных
дублей. Backend OpenAPI остаётся источником истины для HTTP-контрактов.

## Структура

```text
lib/
├── main.dart
├── app/
│   ├── app.dart                 # composition root и session cleanup
│   ├── router/                  # GoRouter, Routes, AppGate
│   └── shell/                   # единственный indexed tab shell
├── core/
│   ├── config/                  # APP_ENV и endpoint policy
│   └── network/                 # ApiClient, safe errors и metadata logging
├── features/
│   ├── auth/                    # session, login, bootstrap
│   ├── onboarding/              # canonical profile completion
│   ├── discovery/               # feed и reactions
│   ├── likes/                   # incoming/outgoing/favorites
│   ├── match/                   # mutual-match handoff
│   ├── chat/                    # REST history + realtime socket
│   ├── profile/                 # own/public profile и edit
│   ├── settings/                # account, preferences, delete, about
│   └── subscription/            # backend checkout/status/entitlement
└── shared/
    ├── media/                   # configured network-media resolution
    ├── theme/                   # semantic Midnight Aura tokens
    └── ui/                      # canonical reusable components
```

Новых общих `lib/data`, `lib/domain`, `core/socket`, event-bus или
feature-independent store trees создавать не нужно. Feature-specific model,
repository и controller остаются рядом с feature. Cross-feature код выносится
в `core`/`shared` только когда у него есть минимум два реальных consumer.

## Composition root и маршруты

`main.dart` создаёт `ProviderScope` и `App`. `App`:

- создаёт единственный `GoRouter`;
- запускает canonical chat socket manager/realtime listener;
- слушает завершение secure session;
- очищает private Riverpod state при logout/session invalidation;
- применяет только `AppTheme.midnight()`.

Навигация выполняется непосредственно через GoRouter и `Routes`. Event bus,
named `Navigator` routes и второй router запрещены.

| Path | Canonical screen | Вход / назначение |
| --- | --- | --- |
| `/bootstrap` | `AppBootstrapScreen` | initial session/profile resolution |
| `/welcome` | `WelcomeScreen` | signed-out landing |
| `/auth/phone` | `PhoneAuthScreen` | login/registration intent |
| `/register` | `RegistrationScreen` | canonical registration |
| `/onboarding` | `OnboardingScreen` | incomplete authenticated profile |
| `/discover` | `DiscoveryScreen` | shell tab 0 |
| `/chats` | `ChatListScreen` | shell tab 1 |
| `/likes` | `LikesScreen` | shell tab 2 |
| `/profile` | `ProfileScreen` | shell tab 3 |
| `/discover/profile/:id` | `PublicProfileScreen` | real public profile |
| `/match/:userId` | `MatchScreen` | mutual match |
| `/chat/:id` | `ChatScreen` | one conversation |
| `/profile/edit` | `EditProfileScreen` | canonical profile form |
| `/profile/preview` | `OwnProfilePreviewScreen` | saved public preview |
| `/settings` | `SettingsScreen` | settings root |
| `/settings/account` | `AccountSettingsScreen` | real account facts |
| `/settings/discovery` | `DiscoveryPreferencesScreen` | persisted filters |
| `/settings/account/delete` | `DeleteAccountScreen` | destructive flow |
| `/settings/about` | `AppInformationScreen` | installed app metadata |
| `/premium` | `SubscriptionScreen` | plans, checkout and active access |

`AppGate` является единственным redirect guard:

```text
checking/loading/unavailable -> /bootstrap
signed out                   -> public auth routes
onboarding required          -> /onboarding
ready                        -> requested private route or /discover
```

Android/iOS app links пока не настроены. Платёжный redirect не активирует
подписку: lifecycle/manual refresh всегда проверяет backend status.

## State management

Riverpod — единственный application state mechanism.

- Providers и notifiers объявляются внутри `features/*/application`.
- Screen наблюдает state и вызывает notifier action.
- Repository provider получает shared `ApiClient`.
- Локальные `TextEditingController`, focus, scroll, animation и modal flags
  остаются локальным widget state.
- GoRouter владеет navigation state; stream event bridge не используется.
- `SessionStorage` — единственный secure token store и реализация
  `ApiTokenStore`.
- `ApiClient` всегда получает token store явно; скрытый storage singleton
  запрещён.
- Logout/session invalidation очищает private providers из `App`, а не
  создаёт параллельный global store.

MobX, generated stores, service locator и process-wide mutable singleton не
являются частью canonical architecture.

## Data flow

```text
Screen / reusable view
        ↓ user intent
Riverpod controller/notifier
        ↓ typed model or command
Feature repository boundary
        ↓
Shared ApiClient + SessionStorage
        ↓ Bearer / refresh / safe error mapping
Backend OpenAPI endpoint
        ↑
Typed feature model and explicit UI state
```

Repository boundaries и текущие Dio implementations находятся в
feature-specific `domain/*_repository.dart`; storage implementation допустим в
feature `data/`, если он не является HTTP contract. Экран не обращается к Dio,
secure storage или Socket.IO напрямую.

`publicProfileSeedFromDiscovery` не создаёт fake profile: он переносит только
уже полученные от backend поля Discovery в initial render и затем заменяется
canonical public-profile response.

## Разрешённые network paths

Новый endpoint сначала фиксируется в backend OpenAPI и только затем добавляется
в соответствующий feature repository.

| Feature | Path family |
| --- | --- |
| Auth | `/auth/send_code`, `/check_code`, `/check_phone`, `/register`, `/login`, `/whoami`, shared `/auth/refresh_token` |
| Discovery / Match | `/match/find_matches`, `/user/{id}`, `/likes/{action}/{id}` |
| Likes | `/likes/liked_me`, `/liked_users`, `/favorites` |
| Profile | `/user/me`, `/user/update_user`, photos/avatar, `/interest/*`, `/attributes/*`, `/service/upload/profile_photo` |
| Chat | `/communication/create_chat`, `/get_chats`, `/{chatId}`, `/{chatId}/messages` |
| Settings | `/user/delete_user`; installed package metadata uses the active platform bridge |
| Subscription | `/subscriptions`, `/active`, `/checkout`, `/payments/{orderId}`, `/cancel`; demo result endpoint only in demo mode |

`ApiClient` owns Bearer injection, one shared refresh, one retry, typed error
mapping and `SafeApiLogInterceptor`. Разрешено логировать только method, path
без query, status, duration, safe backend code и request id. Headers, bodies,
tokens, personal data и PaymentURL запрещены.

## Chat transport

Chat имеет один deliberate transport split:

```text
GET /communication/{chatId}/messages
    -> initial page and older cursor pages

Socket.IO join_chat
    -> room acknowledgement

Socket.IO new_message / completer / status events
    -> realtime changes only
```

`ChatMessagesController` объединяет REST rows, realtime rows, optimistic send,
ack/retry и reconnect reconciliation. Cursor opaque; page limit 30; history
ordered oldest-to-newest. Socket не запрашивает `get_messages` и не переносит
full history. Второй socket client или второй message store запрещён.

## Midnight Aura theme hierarchy

```text
AppTheme.midnight()
  └── AppTokens
      ├── semantic palette / typography / spacing / radii / motion
      ├── AppGradientScaffold + static AppBackdrop
      ├── GlassSurface(GlassLevel.navigation|overlay|sheet)
      └── feature/shared components
```

Канонические primitives:

- `AppGradientScaffold`, `AppBackdrop`, `GlassSurface`;
- `GlassNavigationBar` — единственная нижняя навигация;
- `AppTopBar`, `GlassSheet`, `GlassIconButton`;
- `PrimaryActionButton`, `SecondaryActionButton`;
- `EmptyState`, `ErrorState`, `SkeletonLoader`;
- shared profile, Discovery и network-image components;
- feature-specific components внутри `features/*/presentation`.

Обычный list/card content использует solid/translucent surface без backdrop
blur. Shader background, continuously ticking atmospheric layer, compatibility
theme aliases и compatibility widgets удалены. Новый public component должен
иметь реальный consumer, semantic state, 48 px target и test coverage.

## Demo и production

`AppConfig` определяет границу окружений:

- debug/profile без define безопасно запускаются как `demo`;
- release без define выбирает `production`;
- demo/development могут использовать Android emulator host `10.0.2.2`;
- production требует явные HTTPS/Socket endpoints, запрещает local hosts и
  `DEMO_MODE=true`;
- demo account shortcut, demo OTP и demo payment controls видимы только когда
  разрешены конфигурацией;
- demo использует те же repository/DTO/state paths и backend fake provider,
  а не отдельные UI stores или статические production profiles.

Flutter никогда не хранит TerminalKey, bank Password, PAN/CVV, RebillId или
CardId, не генерирует банковский Token и не активирует entitlement по redirect.

## Dependencies

Разрешённый runtime set после DES-08:

| Package | Роль |
| --- | --- |
| `dio` | shared HTTP transport |
| `flutter_riverpod` | application state and DI |
| `flutter_secure_storage` | canonical session/preferences storage backing |
| `go_router` | router, guard and shell |
| `socket_io_client` | chat realtime only |
| `image_picker` | profile gallery selection |
| `url_launcher` | external bank PaymentURL |
| `uuid` | checkout idempotency key |
| `collection` | typed domain helpers |

Dependency добавляется только для подтверждённого production consumer, после
проверки platform/build impact. UI package не должен создавать вторую theme,
router, state или network architecture.

## Правила для нового кода

1. Сначала проверь OpenAPI и существующий feature; не создавай параллельный
   экран, route, model, controller или repository.
2. Используй `Routes` для каждого path и `AppGate` для auth/onboarding policy.
3. Размещай async state в Riverpod feature controller; ephemeral view state —
   локально в widget.
4. Все HTTP вызовы проходят через injected `ApiClient`; все tokens — через
   `SessionStorage`.
5. History чата остаётся REST cursor pagination, realtime — Socket.IO.
6. Используй semantic `AppTokens` и canonical components; новый glass region
   должен укладываться в blur budget.
7. Не добавляй fake production data, неполезные placeholders, AI/compatibility
   claims или UI без backend contract.
8. Не логируй secrets, bodies, payment URLs или personal data.
9. До удаления файла докажи отсутствие import, route, provider, dynamic,
   generated, platform и test consumers.
10. Обновляй behavior/widget/golden tests и выполняй полный gate:

```powershell
flutter clean
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
flutter run --profile
```

Pre-deletion evidence и решения DES-08 находятся в
`docs/architecture/LEGACY_CLEANUP_AUDIT.md`.

