# Auth and Onboarding — Midnight Aura Glass

## Scope

DES-06 redesigns application bootstrap, the signed-out welcome experience,
phone authentication, OTP verification, account registration, and the
first-profile setup flow. It also hardens route guarding, session refresh, and
logout cleanup. Discovery, public profiles, Match, Chats, Likes,
Subscription, the own-profile UI, and Settings presentation remain outside the
visual scope.

The backend and its OpenAPI contract are immutable for this task. The screens
only expose behavior supported by the current controllers and schemas.

## Actual authentication contract

The only supported identifier is an 11-digit Russian phone number:

- digits only after client normalization;
- the first digit is `7`;
- an entered leading `8` is normalized to `7`;
- there is no email, username, password, social, or biometric login.

Authentication is OTP-based. The current backend generates a six-digit numeric
code. It stores the code in `TemporaryCode`, but exposes neither an expiration
timestamp nor a resend interval. Production sends the code by SMS; demo returns
the code in `verification_code`.

| Operation | Endpoint | Request | Success | Relevant errors |
| --- | --- | --- | --- | --- |
| Send code | `POST /auth/send_code` | query `phone_number` | `verification_code`, empty outside demo | invalid phone `400`, code `666`; server `500` |
| Verify code | `POST /auth/check_code` | query `phone_number`, `verification_code` | message | invalid code `400`, code `604` |
| Check account | `POST /auth/check_phone` | query `phone_number` | the endpoint deliberately reports status as an error response | new account `400`, code `667`; existing account `400`, code `612` |
| Login | `POST /auth/login` | query `phone_number`, `code` | access and refresh tokens | invalid code/user/phone `400`; server `500` |
| Register | `POST /auth/register` | JSON `UserCreate` fields below | access and refresh tokens | duplicate phone `400`; unverified phone `400`; city missing `404`; validation `422` |
| Identify session | `GET /auth/whoami` | bearer access token | integer `id`, gender, subscription and timestamps | invalid access `401`; missing user `404` |
| Refresh | `POST /auth/refresh_token` | query `refresh_token` | replacement access and refresh tokens | expired/invalid refresh `401`; server `500` |

There is no backend logout endpoint. Logout is a local session revocation:
secure tokens are removed and all private client state is discarded. The
server-side refresh record is replaced on the next successful login.

### Tokens and storage

The backend normally issues an access token for 30 minutes and a refresh token
for 168 hours, but the client does not calculate validity from those defaults.
It reacts to authenticated requests and `401` responses.

Both tokens are stored through `flutter_secure_storage`. `Bearer ` is removed
before storage and added only to the request header. Tokens, authorization
headers, OTP values, and registration data are not written to application logs.
No token is stored in `SharedPreferences`.

The API client serializes concurrent refresh attempts with one shared future.
Every failed request is retried at most once. An invalid or expired refresh
clears the session. A timeout, connection error, or transient refresh server
failure keeps the stored session and becomes a retryable bootstrap error.

## Registration contract

`POST /auth/register` creates the account and initial profile in one operation.
The backend does not support an empty account followed by a separate base
profile creation request. Registration therefore collects only the fields
required by `UserCreate`, across small sequential screens:

| Field | Format | Client validation | Server validation |
| --- | --- | --- | --- |
| `phone_number` | canonical 11 digits starting with `7` | normalized before OTP | Pydantic digit, length, and prefix checks |
| `first_name` | text | trimmed, non-empty | required string |
| `last_name` | text | trimmed, non-empty | required string |
| `date_of_birth` | ISO `YYYY-MM-DD` | date picker and at least 18 years | required date; no server age rule |
| `gender` | `female`, `male`, or `non-binary` | localized label maps to canonical value | required string; no enum catalog |
| `city_name` | existing city name, optionally `City (Region)` | trimmed, non-empty | case-insensitive city lookup; missing city is `404` |

`verify`, `status`, and nested `attributes` have schema defaults or are unused
by the registration controller and are not collected. There is no Terms or
Privacy URL, acceptance field, or backend consent flag, so DES-06 does not
invent a checkbox or dead document link.

Registration is preceded by successful `check_code`. A busy guard prevents
duplicate account requests. A duplicate account keeps the entered form and
offers phone login.

## Profile setup and completeness

The backend has no `is_complete`, onboarding step, completion endpoint, or
server-enforced photo/interests minimum. DES-06 distinguishes three concepts:

1. **Account registration validity** — the fields required by `UserCreate`.
2. **Client profile-setup readiness** — a documented route-guard calculation.
3. **DES-05 profile completeness score** — a separate own-profile progress
   card; it is not an auth decision.

Client profile-setup readiness is calculated from the canonical result of
`GET /user/me` plus `GET /user/user/photos`:

- non-empty first name;
- date of birth;
- non-empty gender;
- non-empty city;
- non-empty `attributes.what_looking_for`;
- at least one saved interest.

Last name is required for new registration, but the current update controller
does not persist it. It is therefore not used as a legacy-account route guard,
which avoids an unresolvable loop. Biography is optional. The backend photo
minimum is effectively zero, so photos are a real, skippable setup step rather
than a fabricated requirement. The UI states that a primary photo improves the
profile but does not claim the server requires one.

This client readiness rule is the unavoidable fallback for the missing server
completion value. A future backend `is_complete` must replace it.

## Onboarding approach

First setup uses one sequential flow with real step counts:

1. Basic profile, only when a legacy profile is missing updateable registration
   fields.
2. Preferences: required relationship goal and optional biography.
3. Interests: at least one canonical interest for client setup readiness.
4. Photos: existing picker/upload manager, skippable because the server has no
   minimum.
5. Review and canonical completion check.

The normal new-user path begins at Preferences because registration already
saved Basic profile. Progress is shown as `Step N of M`, never as a fabricated
percentage. Completed earlier steps remain reachable with Back.

### Step and endpoint table

| Step | Data | Endpoint | Required | Client validation | Server validation | Next route |
| --- | --- | --- | --- | --- | --- | --- |
| Welcome | auth intent | none | yes while signed out | none | none | phone |
| Phone | `phone_number` | `POST /auth/send_code` | yes | canonical 11 digits | phone validator | OTP |
| OTP | six digits | `POST /auth/check_code`, then `/auth/check_phone` | yes | exactly six numeric digits | stored code and account lookup | Login or Registration |
| Login | verified phone/code | `POST /auth/login` | existing account | double-submit guard | user and stored code | Bootstrap |
| Registration identity | first and last name | deferred to `/auth/register` | yes | trimmed, non-empty | required strings | Birthday |
| Registration birthday | `date_of_birth` | deferred to `/auth/register` | yes | real date, age 18+ | valid date | Gender |
| Registration gender | canonical gender | deferred to `/auth/register` | yes | known client mapping | required string | City |
| Registration city | `city_name` | deferred to `/auth/register` | yes | trimmed, non-empty | existing city | Review |
| Registration review | complete `UserCreate` | `POST /auth/register` | yes | all previous checks | duplicate, code, city, schema | Bootstrap |
| Basic profile resume | first name, birth date, gender, city | `PUT /user/update_user` | only when missing | same base checks | updateable truthy values | Preferences |
| Preferences | biography, `what_looking_for` | `PUT /user/update_user`, `POST /attributes/add_attributes` | goal yes, biography no | goal from catalog | enum description | Interests |
| Interests | canonical interest IDs | `GET /interest/interests_list`, `POST /interest/add_interests` | one for client readiness | non-empty selection | IDs exist | Photos |
| Photos | multipart image, avatar flag | photo endpoints from DES-05 | no server minimum | JPG/PNG/WebP, signature, 10 MiB client limit | supported MIME | Review |
| Review | canonical profile | `GET /user/me`, `GET /user/user/photos` | readiness rule above | no local success assumption | canonical response | Discovery |

## Resume algorithm

The backend profile is always the source of saved truth. An in-memory draft
contains only the current unsaved inputs and survives Back, rebuilds, and
application lifecycle pauses while the process remains alive.

On authenticated bootstrap:

1. load canonical profile and photos;
2. if an updateable base field is missing, open Basic;
3. else if `what_looking_for` is missing, open Preferences;
4. else if interests are empty, open Interests;
5. otherwise enter the main shell.

During a newly active onboarding flow, Photos and Review remain visible after
readiness is reached so the user can finish the sequence explicitly. On a later
restart, canonical readiness routes directly to the main shell. Uploaded
photos, saved interests, and profile values are never reset.

## Bootstrap and navigation graph

```text
bootstrap
├── no session / invalid refresh
│   └── welcome
│       ├── login intent → phone → OTP → login
│       └── registration intent → phone → OTP → registration
├── session network error
│   └── retryable bootstrap state
└── authenticated
    ├── canonical profile not ready → onboarding
    └── canonical profile ready → main shell
```

The GoRouter redirect is the single auth guard. It observes auth, profile, and
active-onboarding state without creating a second navigator:

- bootstrap is the only route while storage/session status is unresolved;
- signed-out users may only open Welcome, phone auth, and Registration;
- authenticated users cannot remain on public auth routes;
- private/deep routes pass through the guard;
- successful login and logout use route replacement;
- completed users cannot reopen onboarding unless they are finishing the
  currently active flow;
- logout removes the private stack, so Back cannot restore it.

## Bootstrap states

Explicit states replace a UI boolean:

- checking secure storage;
- restoring session;
- signed out;
- submitting an auth operation;
- authenticated and loading canonical profile;
- incomplete profile;
- ready profile;
- retryable offline/restore error;
- signing out.

Restore and profile loads each use one in-flight future. The bootstrap view
never shows Welcome before storage is checked and never shows a private screen
before both authentication and profile routing are resolved.

## OTP behavior

The input accepts paste, numeric keyboard input, and the platform one-time-code
autofill hint. It supports manual submit and does not auto-submit. Resend has a
documented 60-second client cooldown because the backend returns no interval.
The timer starts only after a successful send. Busy guards serialize send,
verify, and resend. Changing the phone clears OTP-only state while retaining
the normalized phone.

The backend does not return a distinct expired-code response, so the client can
only distinguish invalid code, network failure, and general server failure.
No fake expiry copy is shown.

## Error policy

- Local field errors stay beside their fields and do not erase other inputs.
- Backend validation is mapped to readable account, code, phone, city, and
  conflict messages; raw JSON is never rendered.
- Network and server failures keep the draft and expose Retry.
- A final `401` after one refresh clears the session once.
- A refresh network/server failure does not prove that the refresh token is
  invalid and therefore does not clear secure storage.
- Registration conflict keeps the verified phone and offers Login.
- Profile completion is accepted only after a canonical reload.

## Logout cleanup

Logout clears secure storage and publishes one signed-out auth state. The app
then invalidates profile/edit, Discovery, Likes, chat list/message, active chat,
public profile, Subscription/access, and onboarding state. The Socket.IO
manager observes the token removal, leaves pending rooms, clears pending sends,
and disconnects. The router replaces the private stack with Welcome.

Settings receives only the minimal integration action required to invoke this
flow; its layout is not redesigned.

## Accessibility

- every control has a minimum 48 × 48 logical-pixel target;
- auth forms use `AutofillGroup`, labels, hints, `Next`/`Done`, and explicit
  focus order;
- OTP exposes a single understandable semantic field;
- progress announces `Step N of M`;
- errors are live regions and are not communicated only by color;
- selected gender/interests include semantic selected state;
- layouts scroll on compact devices and at text scale 1.3;
- high contrast uses semantic token borders;
- transitions respect reduced motion;
- images expose profile-photo labels and never local file paths.

## Performance

Welcome uses one compact glass action panel. Auth/onboarding screens use at most
one top/action glass region; fields and repeated options are solid surfaces.
There is no full-screen `BackdropFilter`, looping animation, or particle layer.

Text controllers are created once and disposed. OTP timers are cancelled.
Bootstrap, registration, verification, refresh, and completion reject duplicate
requests. The interest catalog is cached for the active controller. Profile
photos reuse the DES-05 bounded upload and rendering pipeline.

## Test matrix

Tests use fakes and never production auth:

- bootstrap: no tokens, valid session, refresh, invalid refresh, offline
  refresh, duplicate restore, no signed-out/private flash;
- phone/OTP: validation, demo shortcut, paste-ready six digits, send/resend
  guards, cooldown, account missing/existing, API errors;
- registration: every required field, adult date, canonical gender, retained
  draft, duplicate submit, conflict, successful route transition;
- onboarding: resume step calculation, basic validation, catalog error/retry,
  canonical interest IDs, optional photo step, upload error/retry, canonical
  completion, double completion;
- routing: public/private guards, auth stack replacement, completed onboarding
  guard, logout replacement;
- session: secure storage, one refresh for concurrent `401`s, one retry,
  invalid refresh cleanup, offline refresh retention;
- logout: private providers and socket-visible token state are cleared;
- layout: compact viewport, text scale 1.3, keyboard insets, semantics, high
  contrast, and reduced motion;
- golden harness: Splash, Welcome, phone, OTP, registration, onboarding steps,
  and retry states with animations disabled.

Persisted server completion, server photo minimum, OTP expiry/resend metadata,
Terms/Privacy links, refresh revocation, and photo ordering cannot be tested
because the immutable backend contract does not provide them.
