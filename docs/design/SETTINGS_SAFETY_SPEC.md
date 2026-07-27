# Settings, Account, and Safety — Midnight Aura Glass

## Scope

DES-07 redesigns the authenticated Settings entry point, account information,
Discovery preferences, Subscription entry, logout, account deletion, and
application information. It also audits notification, privacy, legal, block,
report, and blocked-user capabilities.

The backend and OpenAPI contract are immutable for this task. A Settings row is
rendered only when its action has a real route, client capability, storage
contract, or backend endpoint. Discovery, Profile, Match, Chats, Likes,
Subscription checkout, Auth, and Onboarding are unchanged except for the
minimum Settings integration described below.

## Contract audit

The current product supports:

- read-only account identity from the authenticated session;
- request-scoped Discovery filters on `GET /match/find_matches`;
- active Subscription status and the existing Subscription screen;
- local logout through the hardened DES-06 session cleanup;
- account deletion through `DELETE /user/delete_user`;
- Android package version/build information.

The current product does not expose:

- notification-category preferences or OS notification-permission
  infrastructure;
- profile visibility, distance visibility, read receipts, online status, or
  another privacy-settings contract;
- block, unblock, report, complaint-reason, or blocked-users endpoints;
- Privacy Policy, Terms, Community Guidelines, support, or other legal URLs;
- a persisted Discovery-preferences resource;
- maximum distance or interested-gender filters;
- contact editing or verification state intended for account management;
- server logout or refresh-token revocation.

DES-07 therefore hides Notifications, Privacy and safety, Blocked users, Legal,
contact editing, distance, gender preference, and all block/report affordances.
It does not add inert routes, switches, or locally simulated safety behavior.

## Settings structure

```text
Settings
├── Account
│   ├── read-only account reference
│   ├── sign-in method
│   └── Delete account
├── Discovery preferences
│   ├── age range
│   └── backend catalog attribute filters
├── Subscription
│   └── existing Subscription screen
├── App information
└── Sign out
```

The top bar is the only always-visible glass region. Repeated rows and sections
use solid dark surfaces. Confirmation sheets/dialogs may use one additional
glass region. No list row owns a `BackdropFilter`.

## Sources of truth

| Setting/action | Source | Type | Endpoint/storage | Commit model | Error | Rollback |
| --- | --- | --- | --- | --- | --- | --- |
| Account reference | authenticated `AuthUser.id` from `GET /auth/whoami` | server-backed, read-only | auth controller memory | automatic after auth | account section remains available with neutral unavailable copy only if auth state is incomplete | none |
| Sign-in method | actual OTP-only auth architecture | client presentation, read-only | no request | automatic | none | none |
| Discovery age range | `minAge`, `maxAge` query support | client-persisted and server-applied per request | per-user `flutter_secure_storage`; `GET /match/find_matches` query | explicit Save | draft remains visible; inline retry | saved values and current feed remain unchanged until local persistence succeeds |
| Discovery catalog filters | `smokingAttitude`, `alcoholAttitude`, `childrenPreference`, `whatLookingFor`, `appearance`, `religion` | client-persisted and server-applied per request | catalog from `GET /attributes/`; per-user secure storage; `GET /match/find_matches` query | explicit Save | catalog/storage/feed error is section-scoped; draft remains | previous saved preferences remain canonical |
| Subscription | `SubscriptionAccessState` | server-backed, read-only entry | `GET /subscriptions/active`; existing `/premium` route | automatic section load | inline status and Retry; other Settings remain usable | retain last resolved status |
| Sign out | DES-06 local session policy | client security action | secure token storage and private Riverpod caches | confirmed action | local cleanup still completes; there is no server request | not applicable |
| Delete account | backend deletion response | server-backed destructive action | `DELETE /user/delete_user` | warning then final confirmation | keep session and all private state; allow retry | no optimistic mutation |
| App name/version/build | installed Android package | platform-backed, read-only | Android `PackageManager` through a method channel | automatic | neutral unavailable version state and Retry | none |

Only saved Discovery preferences are supplied to the feed. An unsaved draft
never changes a request.

## Account

`GET /auth/whoami` reliably provides the integer account id, but the response
does not expose a phone number, email, username, or user-facing verification
status. `GET /user/me` provides profile data, not account contact data.

The Account screen consequently shows:

- a read-only account reference derived from the authenticated integer id;
- the real sign-in method, phone verification code;
- the Delete account route.

It never renders access/refresh tokens, roles, API details, or a fabricated
verified badge. Contact editing is absent because there is no supported update
and re-verification contract.

## Discovery preferences

### Supported filters

`GET /match/find_matches` accepts these request-scoped query values:

- `minAge` and `maxAge`;
- `smokingAttitude`;
- `alcoholAttitude`;
- `childrenPreference`;
- `whatLookingFor`;
- `appearance`;
- `religion`.

The enum values sent to the match endpoint are the canonical `description`
strings returned by `GET /attributes/`, matching the existing profile catalog
mapping. Empty selections omit their query parameter.

The endpoint also accepts city and height parameters, but DES-07 does not expose
them:

- city requires exact backend naming and Discovery already applies the
  authenticated profile city;
- height has no server min/max bounds, so the requested bounded control cannot
  be implemented without arbitrary client rules.

The backend has no maximum-distance or interested-gender query parameter.
Those controls are absent. The backend itself restricts candidates to the
opposite gender, same city, and a small result limit.

### Validation and persistence

Age has the only real lower bound exposed by current matching behavior: 18.
There is no backend upper bound, so the UI uses accessible integer inputs
instead of a slider with an invented maximum. Both values must be integers at
least 18 and `minimum <= maximum`.

The backend has no preference-save endpoint. DES-07 persists the confirmed
filter object per authenticated user through `flutter_secure_storage` and sends
it to every subsequent match request. This is client persistence for a real
backend query contract, not server persistence. Values survive process restart
for the current session and are cleared on logout/delete to prevent
cross-account private-state leakage.

The screen owns a draft:

1. load the current user's saved preferences and the attribute catalog once;
2. edit draft values without changing Discovery;
3. disable Save while unchanged or invalid;
4. serialize one Save at a time;
5. write the complete validated preference value to storage;
6. publish it as canonical client state;
7. refresh Discovery exactly once with the new query;
8. keep the draft and previous canonical feed if storage fails.

Leaving with unsaved changes asks whether to discard them.

## Subscription

Settings reuses `subscriptionAccessControllerProvider` and the existing
`SubscriptionScreen`. It displays section-level loading/error state, the active
plan name and end date when present, or Free access when inactive.

The Settings row uses `/premium`; it does not create a second subscription
screen or call T-Bank. Auto-renew, cancellation, payment-card management, next
charge, and RebillId controls remain absent because recurring execution is not
part of the current product stage.

## Notifications and privacy

Only push-token registration exists. It is not a user notification-preference
contract and it exposes no category values. The Flutter client also has no
current OS notification-permission state abstraction. Notifications are
therefore hidden.

The old process-memory notification boolean and its unused MobX chat store were
removed in DES-08. The production Riverpod chat flow has no notification
preference field, so the deleted boolean is not revived as a Settings control.

There are no backend privacy fields for visibility, presence, distance, read
receipts, or Discovery participation. Privacy controls are hidden. DES-07 adds
no optimistic switches and needs no rollback protocol for this absent feature.

## Block, report, and blocked users

No block, unblock, report, complaint, complaint-reason, or blocked-users route
exists in the backend or Flutter architecture. The `blocked_until` field on
likes is an outgoing-like rate limit, not a safety block.

Accordingly:

- Public Profile and Chat receive no new overflow actions;
- Settings has no Blocked users route;
- no localized reason is mapped to a made-up canonical value;
- no client-only removal is presented as a successful block/report;
- no report details can enter application logs.

When the backend adds a canonical safety contract, one shared action controller
must be integrated from Profile and Chat and must update Discovery, Likes, Chat,
socket rooms, unread state, and the blocked-users resource only after server
success.

## Legal

There are no configured Privacy Policy, Terms of Service, Community Guidelines,
or support URLs. Legal is hidden rather than opening an empty WebView or an
unknown hardcoded URL. App information must not imply that missing documents
are available.

## Logout

There is no backend logout endpoint. A glass confirmation sheet invokes the
DES-06 local logout controller once. Secure tokens are cleared, causing the
socket manager to disconnect and leave pending chat state. The application
invalidates onboarding, profile, edit/preview, Discovery, Likes, chat
list/messages/active registry, Subscription/access, public-profile, and
Settings preference state.

The per-user persisted Discovery preference value is also deleted. GoRouter
replaces the private stack with Welcome; Android Back cannot recover a private
screen. A storage cleanup error never preserves a partially authenticated
session in the UI.

## Account deletion

`DELETE /user/delete_user` is the only deletion operation. Its current
implementation:

- marks `User.deleted = true`;
- replaces the stored phone number with a timestamp-prefixed value;
- clears the deleted user's participant id from existing chats;
- retains chat/message records;
- returns success only after the database commit.

The endpoint does not document recovery, subscription cancellation, immediate
refresh-token revocation, or erasure of every related record. The UI describes
only the guaranteed effects: the account is marked deleted, the user is
disconnected from existing chats, and the action has no client recovery flow.
It explicitly does not promise full data erasure or subscription cancellation.

Deletion uses two conscious steps:

1. a dedicated warning screen;
2. a final destructive confirmation dialog.

The request blocks duplicate submit and route Back while in flight. On backend
success, and only then, the client performs the same local logout/private-state
cleanup and replaces navigation with Welcome. On failure it preserves the
session, all caches, and the stable warning screen with a readable retry error.

The backend currently leaves already-issued tokens technically valid until
their normal expiry. The client clears them after success, but server-side token
revocation requires a separate backend task.

## App information

The app name is the product name shown by the client. Version name and build
number come from the installed Android package through `PackageManager`; they
are never hardcoded into a Settings widget. Failure produces a retryable
unavailable state.

API base URL, environment, branch, commit SHA, debug flags, secrets, and signing
information are never displayed.

## Navigation

Private routes:

```text
/settings
/settings/account
/settings/discovery
/settings/account/delete
/settings/about
/premium
```

Settings subroutes use `push`, so ordinary Back returns to the prior Settings
screen. Successful logout/delete uses route replacement. The existing global
GoRouter auth guard protects direct and deep links to every Settings route;
these screens do not create another router or a global provider.

## Loading and error policy

- Settings renders immediately; Subscription resolves independently.
- Discovery preferences separate storage loading, catalog loading, saving, and
  feed-refresh failure.
- A catalog error keeps the age controls usable but disables unavailable
  catalog choices and exposes Retry.
- A preference Save error retains the complete draft.
- Subscription error does not hide Account, Discovery, About, or Sign out.
- App information failure exposes Retry without debug details.
- Delete failure leaves the account authenticated and exposes Retry.
- Raw backend payloads and exceptions are never rendered.

## Security

- access/refresh tokens and authorization headers are not displayed or logged;
- Discovery storage is namespaced by authenticated user and removed with the
  private session;
- deletion clears local data only after confirmed backend success;
- socket disconnect follows token removal on logout and delete;
- private providers and navigation are invalidated centrally;
- destructive actions reject duplicate requests;
- delete errors do not accidentally log the user's identity or token;
- report text cannot be logged because report UI is absent;
- App information excludes internal endpoints and build provenance.

## Accessibility and performance

- every actionable target is at least 48 × 48 logical pixels;
- rows use button, enabled, selected, loading, status, and destructive semantics
  where applicable;
- destructive labels state the consequence and do not rely only on red;
- long titles/subtitles wrap while trailing controls remain bounded;
- forms scroll above keyboard insets on compact screens and at text scale 1.3;
- age inputs have labels, numeric keyboards, error text, and keyboard
  alternatives by design;
- errors use live regions;
- high contrast strengthens semantic borders;
- reduced motion avoids list/confirmation flourishes;
- at most the top bar and one modal sheet blur simultaneously;
- repeated Settings rows are solid and use local press feedback;
- controllers deduplicate storage, catalog, feed refresh, logout, and deletion
  requests.

## Test matrix

Tests use fake repositories/storage/platform channels and no production account:

- Settings: normal, section loading/error, hidden unsupported sections,
  Account/Discovery/Subscription/About routing, long text, text scale 1.3,
  compact viewport;
- preferences: initial values, restart restoration, valid/invalid ages,
  canonical enum mapping, dirty state, disabled unchanged Save, storage error,
  draft preservation, duplicate Save, one Discovery refresh, unsaved Back;
- Subscription row: loading, inactive, active plan/date, error and retry;
- logout: open, cancel, confirm, duplicate tap, secure storage clear,
  preference clear, socket-visible token removal, private-provider
  invalidation, route replacement and clean subsequent login;
- delete: warning, cancel, final confirmation, in-flight Back guard, duplicate
  submit, backend error/retry, success-only local cleanup and route replacement;
- App information: platform success, unavailable and retry;
- golden harness: Settings normal/long, Account, Discovery preferences, logout
  confirmation, delete warning/loading/error, and App information.

Notification/privacy and safety test suites are intentionally absent until
their real contracts exist. Manual checks cover offline/slow requests, double
taps, small Pixel viewport, text scale, system Back, logout/login cleanup, and
the backend deletion response.
