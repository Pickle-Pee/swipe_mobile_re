# Subscription API v1

Статус: backend и Flutter-клиент реализованы по контракту, 2026-07-13. Backend OpenAPI — источник истины. Полный аудит: `swipe_api/docs/integrations/TBANK_SUBSCRIPTION_PLAN.md`.

## Правила

Base URL — `REST_API_URL`; все user endpoints требуют Bearer. JSON snake_case, UTC ISO-8601, RUB integer minor units. Flutter отправляет только tariff id и Idempotency-Key — не цену, order/customer/phone/status. SuccessURL/app link только запускает refresh. Карта вводится на внешней форме банка.

## Единый контракт

`GET /subscriptions` (старый `/subscriptions/` временно deprecated alias):

```json
{"subscriptions":[{"id":1,"name":"Premium 1 month","description":"Premium access for 30 days","price_minor":49900,"currency":"RUB","duration_days":30,"is_active":true,"renewable":false}]}
```

`POST /subscriptions/checkout`, header `Idempotency-Key: <UUID>`:

```json
{"subscription_id":1}
```

201 first / 200 replay:

```json
{"order_id":"sub_42_20260712_01J...","payment_id":"1234567890","payment_url":"https://securepay.tinkoff.ru/...","status":"pending","amount_minor":49900,"currency":"RUB","expires_at":"2026-07-12T19:30:00Z"}
```

`payment_id/payment_url/expires_at` nullable; same key with other request is 409.

`GET /subscriptions/payments/{order_id}`:

```json
{"order_id":"sub_42_20260712_01J...","payment_id":"1234567890","status":"succeeded","subscription_activated":true,"subscription":{"subscription_id":1,"name":"Premium 1 month","start_at":"2026-07-12T19:05:00Z","end_at":"2026-08-11T19:05:00Z","renewable":false},"failure_code":null,"failure_message":null,"updated_at":"2026-07-12T19:05:01Z"}
```

Payment/subscription/failure fields nullable; only owner.

`GET /subscriptions/active`: always `{"subscription":null}` or same subscription object.

`POST /subscriptions/cancel`, no body, idempotent:

```json
{"subscription":{"subscription_id":1,"name":"Premium 1 month","start_at":"2026-07-12T19:05:00Z","end_at":"2026-08-11T19:05:00Z","renewable":false}}
```

`POST /subscriptions/webhooks/tbank` is backend-only. Valid processed/duplicate/stale notification returns HTTP 200 text/plain `OK`.

## Status и UI

`pending`, `requires_action`, `processing`, `succeeded`, `failed`, `canceled`, `refunded`, `partially_refunded`.

Mapping: `NEW/FORM_SHOWED -> pending`; `AUTHORIZING/3DS_*/AUTHORIZED/CONFIRMING -> processing`; `CONFIRMED -> succeeded`; `REJECTED/AUTH_FAIL/DEADLINE_EXPIRED/ATTEMPTS_EXPIRED -> failed`; `CANCELED/REVERSED/PARTIAL_REVERSED -> canceled`; refund in progress -> processing; partial/full refund -> corresponding status.

UI flow:

```text
initial -> loadingPlans -> plans | empty | error
plans -> creatingCheckout -> openingPayment -> awaitingConfirmation
awaitingConfirmation -> succeeded | failed | canceled | timedOut
succeeded -> refresh active subscription + profile
```

Один in-flight checkout и polling timer на order; bounded backoff; immediate refresh on resume/app link; dispose cancels timer. Link never sets success.

## Errors

```json
{"error":{"code":"subscription_not_found","message":"Subscription is not available","retryable":false,"request_id":"01J..."}}
```

404 `subscription_not_found/payment_not_found`; 409 `subscription_inactive/checkout_already_pending/idempotency_conflict`; 502 `payment_initialization_failed`; 503 retryable `payment_provider_unavailable`; 401 `unauthorized`; 422 `validation_error`.

## Dart target models

```dart
enum PaymentStatus { pending, requiresAction, processing, succeeded, failed, canceled, refunded, partiallyRefunded }
class SubscriptionPlan { final int id, priceMinor, durationDays; final String name, currency; final String? description; final bool isActive, renewable; }
class CheckoutRequest { final int subscriptionId; Map<String,dynamic> toJson()=>{'subscription_id':subscriptionId}; }
class CheckoutResponse { final String orderId; final String? paymentId; final Uri? paymentUrl; final PaymentStatus status; final int amountMinor; final String currency; final DateTime? expiresAt; }
class ActiveSubscription { final int subscriptionId; final String name; final DateTime startAt, endAt; final bool renewable; }
class PaymentStatusResponse { final String orderId; final String? paymentId; final PaymentStatus status; final bool subscriptionActivated; final ActiveSubscription? subscription; final String? failureCode, failureMessage; final DateTime updatedAt; }
```

Unknown/malformed values fail visibly. Display price derives from minor units and is never authoritative input.

## Compatibility and environments

`POST /subscriptions/init_payment` удалён из платёжного контракта. В течение одного переходного backend-релиза route помечен deprecated и всегда отвечает `410 Gone`:

```json
{"detail":{"code":"LEGACY_PAYMENT_ENDPOINT_REMOVED","message":"Use POST /subscriptions/checkout"}}
```

Ответ не зависит от Authorization или body; endpoint не читает клиентские `orderId/amount/customerKey/phone`, не пишет в БД и не вызывает банк. Клиент не должен вызывать или повторять этот endpoint: единственная замена — `POST /subscriptions/checkout` только с `subscription_id` и `Idempotency-Key`. После переходного релиза legacy route удаляется полностью.

Replace legacy `price/duration/features` with `price_minor/duration_days/description` after backend deployment. Remove client `orderId/amount/customerKey/phone`; never call nonexistent `activate_subscription`. Migrate legacy singleton/MethodChannel to repository on shared `ApiClient` and Riverpod. `/premium` currently has no auth guard.

Demo uses backend fake provider and same DTO/state path, with visible label; test DEMO terminal and production secrets remain backend-only. Production forbids demo/local URLs. Automatic recurring Charge is outside this stage; `renewable` is metadata until a separate approved task.

Buyer deployment, build commands, app-link policy and production limitations are documented in `docs/SUBSCRIPTION_BUYER_HANDOFF.md`.
