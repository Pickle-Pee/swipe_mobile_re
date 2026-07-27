# DES-08 legacy cleanup audit

Дата аудита: 2026-07-27. Базовая ревизия:
`5e80dd7` (`codex/cleanup-midnight-aura-legacy`, после fast-forward на
завершённую ветку DES-07).

Этот документ фиксирует доказательства использования до удаления кода.
Backend, OpenAPI и транспортные контракты в DES-08 не меняются.

## Методика

Проверка выполнялась не только по совпадению имён:

1. Построено транзитивное замыкание Dart `import`, `export` и `part` от
   `lib/main.dart`.
2. Для каждого кандидата выполнен поиск по `lib`, `test`, router, Riverpod
   providers, фабрикам, строковым путям, `Navigator`/GoRouter и package imports.
3. Отдельно проверены `part`/`part of`, generated MobX-файлы, asset manifest,
   `pubspec.yaml`, platform resources и тестовые импорты.
4. Проверены runtime-регистрации, строковые имена событий Socket.IO и возможные
   динамические обращения. В приложении нет `dart:mirrors`, service locator или
   фабрики, которые создают перечисленные ниже типы по имени.
5. Для маршрутов построена карта входов, выходов, параметров и guard-логики.

Результат import-графа до удаления: 111 Dart-файлов в `lib`, 84 достижимы от
`main.dart`, 27 недостижимы. Все ссылки на эти 27 файлов находятся только
внутри того же недостижимого подграфа; тесты их не импортируют.

Использованные проверки:

```powershell
rg --files lib test
rg -n "import|export|part|part of" lib test
rg -n "Routes\.|GoRoute|context\.(go|push)|Navigator\." lib test
rg -n "get_messages|new_message|join_chat|PaymentURL|RebillId" lib test docs
rg -n "BackdropFilter|Color\(0x|Colors\.|LinearGradient" lib
rg -n "assets/|mobx|socket_io_client|url_launcher|image_picker|uuid" lib test pubspec.yaml
```

## Карта канонических маршрутов

Все зарегистрированные экраны являются частью текущего пользовательского пути.
Android/iOS app links не настроены: platform manifest содержит только launcher
intent, поэтому столбец «direct» означает прямой GoRouter URL внутри приложения.
Любой не-public URL проходит через единый `AppGate`.

| Route | Экран и входы | Выходы | Guard / direct | Legacy-альтернатива | Решение |
| --- | --- | --- | --- | --- | --- |
| `/bootstrap` | `AppBootstrapScreen`; initial route и session refresh | redirect по `AppGate` | специальное loading/unavailable состояние | нет | KEEP |
| `/welcome` | `WelcomeScreen`; signed-out redirect | login или registration phone | public | нет | KEEP |
| `/onboarding` | `OnboardingScreen`; профиль требует onboarding | `/discover` | только `onboardingRequired`; ready redirect | нет | KEEP |
| `/auth/phone` | `PhoneAuthScreen`; `intent` через query/extra | `/register`, `/bootstrap`, `/welcome` | public | `/login`/отдельный registration экран отсутствуют | KEEP |
| `/register` | `RegistrationScreen`; phone через typed `extra` | `/bootstrap`, `/auth/phone` | public | нет | KEEP |
| `/discover` | `DiscoveryScreen`; первая shell-вкладка | public profile, match, likes, chats | authenticated/ready | нет | KEEP |
| `/chats` | `ChatListScreen`; shell-вкладка, optional `userId` query | chat, discover | authenticated/ready | нет | KEEP |
| `/likes` | `LikesScreen`; shell-вкладка | discover, public profile, premium | authenticated/ready | нет | KEEP |
| `/profile` | `ProfileScreen`; shell-вкладка | edit, preview, settings, premium | authenticated/ready | нет | KEEP |
| `/discover/profile/:id` | `PublicProfileScreen`; discovery/likes/chat | discover, likes, match | typed id; optional `source=likes` и profile `extra` | нет | KEEP |
| `/match/:userId` | `MatchScreen`; discovery/public profile | discover, chat | typed user id и optional profile `extra` | нет | KEEP |
| `/chat/:id` | `ChatScreen`; chat list/match | chats, public profile | typed path id | строковый duplicate в router/match | MIGRATE к `Routes.chat` |
| `/profile/edit` | `EditProfileScreen`; own profile | back/guarded save flow | optional typed section `extra` | нет | KEEP |
| `/profile/preview` | `OwnProfilePreviewScreen`; own profile | back | authenticated/ready | нет | KEEP |
| `/settings` | `SettingsScreen`; own profile | account, discovery settings, premium, about, logout | authenticated/ready | нет | KEEP |
| `/settings/account` | `AccountSettingsScreen`; settings | delete account, settings | authenticated/ready | нет | KEEP |
| `/settings/discovery` | `DiscoveryPreferencesScreen`; settings | settings с unsaved guard | authenticated/ready | нет | KEEP |
| `/settings/account/delete` | `DeleteAccountScreen`; account | account или welcome | authenticated/ready; direct URL guarded | нет | KEEP |
| `/settings/about` | `AppInformationScreen`; settings | settings | authenticated/ready | legal/privacy placeholders не зарегистрированы | KEEP |
| `/premium` | `SubscriptionScreen`; likes/profile/settings | likes/back | authenticated/ready; payment app link отсутствует | старого payment route нет | KEEP |

## Подтверждённый недостижимый подграф

Обозначения: REMOVE — удалить; MIGRATE — сначала перевести потребителя на
канонический путь; KEEP — оставить; REVIEW — не удалять без отдельной задачи.

### Providers, network и socket

| Путь | Тип | Почему legacy и где искалось использование | Решение и риск |
| --- | --- | --- | --- |
| `lib/app/providers/providers.dart` | Riverpod stubs | Содержит только nullable/dynamic заглушки и TODO. Нет watcher/reader/import в достижимом графе или тестах. | REMOVE. Низкий риск: production providers живут внутри `features/*/application`. |
| `lib/core/network/chat/chat_http.dart` | старый HTTP client | Импортируется только старым MobX `chat_repo.dart`; canonical chat использует `features/chat/domain/chat_repository.dart`. | REMOVE. Низкий риск после проверки REST pagination tests. |
| `lib/core/network/dio_interceptors.dart` | старые Dio interceptors | Используется только недостижимыми legacy clients; shared `ApiClient` имеет auth refresh и `SafeApiLogInterceptor`. | REMOVE. Низкий риск. |
| `lib/core/network/likes/likes_http.dart` | старый HTTP client | Единственный consumer — недостижимый `likes_repo.dart`; active likes repository находится в `features/likes`. | REMOVE. Низкий риск. |
| `lib/core/network/matches/matches_http.dart` | старый HTTP client | Нет production/test consumer вне legacy group; match/discovery идут через feature repositories. | REMOVE. Низкий риск. |
| `lib/core/network/photo_http/photo_http.dart` | старый HTTP client | Нет достижимого provider/repository; загрузка фото реализована canonical profile repository. | REMOVE. Низкий риск. |
| `lib/core/network/user/user_http.dart` | старый HTTP client | Импортируется только недостижимыми profile/registration stores. | REMOVE. Низкий риск. |
| `lib/core/socket/socket.dart` | второй Socket.IO client | Недостижим от `main.dart`; единственный клиент, который ещё запрашивает `get_messages`. Active `features/chat/application/chat_socket.dart` обрабатывает только realtime. | REMOVE. Средний риск, покрыть transport/pagination tests. |

### Models, MobX stores и generated files

| Путь | Тип | Почему legacy и где искалось использование | Решение и риск |
| --- | --- | --- | --- |
| `lib/data/models/attributes_response_user.dart` | legacy DTO | Используется только недостижимыми user/profile stores. | REMOVE. Низкий риск. |
| `lib/data/models/enums.dart` | legacy enum | Ссылки только внутри старого data/network подграфа. | REMOVE. Низкий риск. |
| `lib/data/models/payment_result.dart` | legacy payment DTO | Не входит в Subscription API v1; содержит старые `PaymentURL`/`RebillId` поля. Active flow использует `features/subscription/domain`. | REMOVE. Высокая security-ценность, низкий runtime-риск. |
| `lib/data/models/saved_card.dart` | legacy card DTO | Нет consumer; canonical Flutter не хранит карточные реквизиты/CardId. | REMOVE. Высокая security-ценность, низкий runtime-риск. |
| `lib/data/repositories/banner/bunner_repo.dart` | legacy store | Нет импорта, provider или route consumer; опечатка имени сохранена только в файле. | REMOVE. Низкий риск. |
| `lib/data/repositories/chat/chat_info.dart` | MobX model | Часть только старого `ChatStore`; тесты и active chat не импортируют. | REMOVE. Низкий риск. |
| `lib/data/repositories/chat/chat_info.g.dart` | generated MobX | `part of` только недостижимого `chat_info.dart`; отдельно не импортируется. | REMOVE вместе с source. |
| `lib/data/repositories/chat/chat_repo.dart` | MobX store | Недостижим; дублирует Riverpod chat controllers и full-history socket API. | REMOVE. Средний риск, сохранить REST history/realtime tests. |
| `lib/data/repositories/chat/chat_repo.g.dart` | generated MobX | `part of` только недостижимого store. | REMOVE вместе с source. |
| `lib/data/repositories/chat/message.dart` | MobX model | Используется только старым ChatStore/socket. Canonical `ChatMessage` находится в feature domain. | REMOVE. Низкий риск. |
| `lib/data/repositories/chat/message.g.dart` | generated MobX | `part of` только недостижимой model. | REMOVE вместе с source. |
| `lib/data/repositories/likes/likes_repo.dart` | MobX store | Нет active route/provider consumer; likes использует Riverpod feature controller. | REMOVE. Низкий риск. |
| `lib/data/repositories/likes/likes_repo.g.dart` | generated MobX | `part of` только недостижимого store. | REMOVE вместе с source. |
| `lib/data/repositories/profile/profile.dart` | MobX store | Нет active route/provider consumer; own/public profile используют feature controllers. | REMOVE. Низкий риск. |
| `lib/data/repositories/profile/profile.g.dart` | generated MobX | `part of` только недостижимого store. | REMOVE вместе с source. |
| `lib/data/repositories/reg_repo/reg_repo.dart` | MobX store | Нет active consumer; auth/onboarding используют Riverpod и feature repositories. | REMOVE. Низкий риск. |
| `lib/data/repositories/reg_repo/reg_repo.g.dart` | generated MobX | `part of` только недостижимого store. | REMOVE вместе с source. |

### Legacy visual layer

| Путь | Тип | Почему legacy и где искалось использование | Решение и риск |
| --- | --- | --- | --- |
| `lib/shared/ui/animated_liquid_background.dart` | compatibility UI | Недостижим от `main.dart`; нет тестового импорта. Midnight Aura использует `AppGradientScaffold`/`AppBackdrop`. | REMOVE. Низкий риск. |
| `lib/shared/ui/shader_liquid_layer.dart` | shader UI | Недостижим; единственный consumer `assets/shaders/liquid.frag`. | REMOVE. Низкий риск. |
| `assets/shaders/liquid.frag` | shader asset | Ссылка только из `shader_liquid_layer.dart` и asset manifest. | REMOVE после Dart consumer. Низкий риск. |
| `GradientButton`, `PillTag` в `lib/shared/ui/liquid_ui.dart` | compatibility widgets | Поиск имён находит только declaration/constructor. Canonical кнопки/чипы уже используются экранами. | REMOVE. Низкий риск. |
| `AiInsightCard`, `SafetyBadge`, `ChatBubbleGlass` в `lib/shared/ui/liquid_ui.dart` | старые/fake UI widgets | Поиск имён находит только declaration/constructor; production flow их не создаёт. | REMOVE. Низкий риск. |
| `GlassTabBar` в `lib/shared/ui/glass_tabbar.dart` | navigation wrapper | Поиск находит только declaration/constructor. Единственная нижняя навигация — `GlassNavigationBar` в `MainShell`. | REMOVE. Низкий риск. |
| `VerifiedBadge` в `lib/shared/ui/midnight_components.dart` | unused widget | Поиск находит только declaration/constructor; verified state не приходит из текущего API. | REMOVE. Низкий риск. |

## Кандидаты на консолидацию

| Путь / символ | Доказательство | Решение и риск |
| --- | --- | --- |
| `lib/app/providers/navigation_events_provider.dart`, `lib/core/events/navigation_event.dart` | `App` подписывается на stream, но в достижимом графе нет producer вызова `navigate()`. Единственный producer был в legacy socket. | MIGRATE: убрать мёртвую подписку и оба файла. Низкий риск; все navigation events идут через GoRouter в экранах. |
| `lib/core/storage/token_storage.dart`, `SecureApiTokenStore` в `api_client.dart` | Production и каждый тестовый `ApiClient` передают `tokenStore`. `SessionStorage` уже реализует `ApiTokenStore`; legacy storage нужен только старым clients. | MIGRATE: сделать `tokenStore` required и удалить дубль. Средний риск; прогнать auth refresh/logout tests. |
| `AppTheme.light()` / `AppTheme.dark()` | Оба метода возвращают `midnight()`. `dark()` вызывается только в `App`; тесты используют `midnight()`. | MIGRATE к одному `AppTheme.midnight()`, затем удалить aliases. Низкий риск. |
| compatibility aliases в `lib/shared/theme/tokens.dart` | Поиск каждого имени вне declaration не дал active consumers; часть используется только удаляемым shader. | REMOVE. Низкий риск; analyzer подтвердит отсутствие ссылок. |
| строковый `path: '/chat/:id'` и `context.go('/chat/$chatId')` | Дублируют `Routes.chat` и `Routes.chatFor`. | MIGRATE. Низкий риск, route tests сохраняются. |

## KEEP / REVIEW

| Область | Результат проверки | Решение |
| --- | --- | --- |
| Экраны | Все файлы экранов под `features/*` зарегистрированы или открываются из зарегистрированных экранов; параллельных pre-redesign screen trees нет. | KEEP. |
| Auth/onboarding guard | Redirect централизован в `app/router/app_router.dart` через `AppGate`; второй production guard не найден. | KEEP единственный guard. |
| Chat architecture | `features/chat/domain/chat_repository.dart` — REST cursor history; `features/chat/application/chat_socket.dart` — realtime only; Riverpod controller объединяет state. | KEEP; удалить только старый full-history socket/MobX store. |
| Subscription | Canonical repository использует только `/subscriptions`, `/active`, `/checkout`, `/payments`, `/cancel` и backend demo endpoint. Прямого T-Bank client нет. | KEEP. |
| Demo content | Fictional demo account и demo subscription controls включаются через `AppConfig.demoMode` и проходят backend contract. Статических fake profiles/messages в production screen layer не найдено. | KEEP официальный demo flow; удалить только orphaned AI compatibility UI. |
| Logging | `SafeApiLogInterceptor` логирует method, path без query, status, timing, safe error code/request id; bodies, headers, tokens и PaymentURL не логируются. `print` найден только в удаляемом legacy подграфе. | KEEP safe logger; удалить legacy logging вместе с clients. |
| Hardcoded visuals | Цветовые константы сосредоточены в `AppTokens`; оставшиеся feature-specific semantic цвета/gradients визуально активны. Единственный active `BackdropFilter` находится в `GlassSurface`; image blur в Likes не является backdrop glass. | KEEP; не выполнять механическую замену layout/semantic значений. |
| Native assets | Android launcher/splash, iOS AppIcon/LaunchImage и web icons используются платформами, а не Dart import-графом. | KEEP. |
| Privacy/legal/blocked routes | В router таких заглушек нет. About показывает фактическую информацию; отдельные legal endpoints/content отсутствуют. | REVIEW отдельной продуктовой задачей, не изобретать UI в cleanup. |

## Dependencies

| Package | Доказательство | Решение |
| --- | --- | --- |
| `mobx` | Импорты только в удаляемых legacy stores/generated group. | REMOVE из `pubspec.yaml` и lock через `flutter pub get`. |
| `dio` | Shared API client и feature repositories. | KEEP. |
| `flutter_riverpod` | Каноническое state management всех features. | KEEP. |
| `flutter_secure_storage` | `SessionStorage`. | KEEP. |
| `go_router` | Единственный router и navigation shell. | KEEP. |
| `socket_io_client` | Канонический realtime chat socket. | KEEP. |
| `collection` | Profile domain helpers. | KEEP. |
| `image_picker` | Profile photo editing. | KEEP. |
| `url_launcher` | Внешняя банковская PaymentURL. | KEEP. |
| `uuid` | Subscription idempotency key. | KEEP. |

## Tests и baseline перед удалением

Legacy stores/clients не имеют самостоятельных production-value tests, поэтому
удалять актуальные tests вместе с ними не требуется. Существующие feature,
router, chat transport, auth, settings и subscription tests должны остаться.

Baseline до cleanup:

- `flutter analyze` не дошёл до analysis из-за timeout запроса advisories к
  `pub.dev`;
- `flutter analyze --no-pub` вернул 228 diagnostics: большая часть относится к
  удаляемым legacy `print`/style issues, но также выявлены compile failures в
  golden skip constants и устаревшие fixtures без обязательного `gender`;
- `flutter test --no-pub` не является зелёным baseline по тем же compile
  failures.

Следующие тестовые файлы требуют MIGRATE, а не удаления:

- `test/features/auth/auth_onboarding_golden_test.dart`;
- `test/features/profile/own_profile_golden_test.dart`;
- `test/features/settings/settings_golden_test.dart`;
- fixtures likes/match/profile/settings, которые создают обновлённые domain
  models без обязательного `gender`.

Golden baselines остаются в репозитории. Причина skip должна быть представлена
валидным boolean для текущего Flutter test API; обновление изображений или
удаление coverage без визуальной проверки запрещено.

## Порядок безопасного удаления

1. Зафиксировать этот аудит отдельным commit.
2. Удалить недостижимые network/MobX/chat/payment файлы; прогнать targeted
   analysis и chat/auth/subscription tests.
3. Консолидировать navigation, token storage, route constants, theme и shared UI.
4. Удалить shader asset и `mobx`, выполнить `flutter pub get`.
5. Исправить только подтверждённые baseline test/analyzer несовместимости.
6. Обновить canonical architecture и устаревшие historical notes.
7. Выполнить полный format/analyze/test/build/profile/manual regression gate.

## Результат выполнения

DES-08 применил все решения REMOVE/MIGRATE из этого аудита:

- удалено 30 Dart-файлов и 4 804 строки недостижимого state/network/socket
  подграфа;
- удалены shader asset, compatibility widgets/tokens/theme aliases, event bus,
  второй token storage и MobX dependency;
- все 81 оставшихся Dart-файла достижимы транзитивно от `lib/main.dart`;
- `flutter analyze --no-pub` — clean;
- `flutter test --no-pub` — 310 tests passed;
- 31 отложенный DES-05/06/07 golden baseline создан, визуально просмотрен и
  включён в обычный test gate.

Итоговый build/profile/manual status дополняется после release gate; canonical
структура закреплена в `CANONICAL_UI_ARCHITECTURE.md`.
