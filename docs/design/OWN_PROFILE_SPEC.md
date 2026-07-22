# Own Profile — Midnight Aura Glass

## Scope

DES-05 redesigns the authenticated user's profile, edit flow, photo
management, and saved-profile preview. It reuses the existing public profile,
Subscription, Settings, routing, Riverpod, image picker, and API client. The
backend and its OpenAPI contract are not changed.

The own-profile screen is a management surface. It never exposes Like, Pass,
Match, Report, Block, popularity, views, compatibility, online presence, or
generated advice.

## Sources of truth

The canonical profile is rebuilt from both existing endpoints:

- `GET /user/me` — identity, biography, subscription flag, interests, and
  profile attributes;
- `GET /user/user/photos` — the current user's photo records.

After every successful mutation the client reloads these endpoints and adopts
their canonical response. A draft or a local photo placeholder is never
published as server state.

Subscription access is resolved by the existing DES-04
`subscriptionAccessControllerProvider`. The `is_subscription` value in
`/user/me` is retained as a real fallback while access is loading, but no
renewal date or recurring-billing control is inferred from it.

## Actual profile model

| Field | Source | Editable | Required | Validation in the current contract | Empty presentation |
| --- | --- | --- | --- | --- | --- |
| `id` | `GET /user/me` | No | Yes | Integer identifier | Profile unavailable state |
| `first_name` | `GET /user/me`, `PUT /user/update_user` | Yes | Registration requires it | Backend defines no length bounds; edit rejects a blank value because the controller ignores empty strings | "Profile" only as a neutral fallback |
| `last_name` | `GET /user/me` | No | Registration requires it | Although present in `UpdateUserRequest`, the controller does not persist it | Omitted |
| `date_of_birth` | `GET /user/me`, `PUT /user/update_user` | Yes | Registration requires it | ISO date; backend has no age range validator | Age omitted; edit can complete the date |
| `gender` | `GET /user/me`, `PUT /user/update_user` | Yes | Registration requires it | Existing client values are `female`, `male`, `non-binary`; backend has no separate enum catalog | Omitted from read view |
| `city_name` | `GET /user/me`, `PUT /user/update_user` | Yes | Registration requires it | Update only applies an exact existing `City.city_name`; backend reports no field error when a value is unknown | "Add city" edit affordance |
| `about_me` | `GET /user/me`, `PUT /user/update_user` | Yes | No | Backend defines no length bound and ignores an empty string; an existing non-empty biography therefore cannot be cleared by this contract | "Add an introduction" edit affordance |
| `status` | `GET /user/me` | No | No | Presence semantics are not reliable for this screen | Never displayed |
| `is_subscription` | `GET /user/me` | No | Yes | Boolean | Free access |
| `interests` | `GET /user/me`, `GET /interest/interests_list`, `POST /interest/add_interests` | Yes | No | IDs must exist in the backend catalog; backend declares no minimum or maximum count | Section is an edit affordance |
| `attributes.height` | `GET /user/me`, `POST /attributes/add_attributes` | Yes | No | Nullable integer; backend declares no range | Omitted |
| enum attributes | `GET /user/me`, `GET /attributes/`, `POST /attributes/add_attributes` | Yes | No | Values must be an enum `description` returned by the catalog; raw enum names are never shown or sent | Omitted |
| `avatar_url` | `GET /user/me` | No direct edit | No | Derived by backend from the avatar photo | Photo placeholder |
| `photos` | `GET /user/user/photos` | Via photo endpoints | No server minimum | See photo contract below | Photo placeholder and Add photo action |
| `deleted` | `GET /user/me` | No | Yes | Account lifecycle field | Never displayed |
| verified status | Not returned by `GET /user/me` | No | N/A | No reliable own-profile value exists | Never displayed |

`appearance`, `smoking_attitude`, `alcohol_attitude`,
`children_preference`, `what_looking_for`, and `religion` all use the same
catalog-driven enum behavior. The relationship goal is
`attributes.what_looking_for` rather than a new profile field.

### Contract mismatches that shape the UI

- `last_name` and nested `attributes` are declared by `UpdateUserRequest`, but
  the current `/user/update_user` controller does not persist them. Last name
  is read-only and attributes use their dedicated endpoint.
- The update controller only assigns truthy values. Empty first name, city,
  gender, date, or biography cannot clear server data. The edit flow omits
  unchanged empty optional values and explains that an existing biography
  cannot currently be cleared.
- City search may return a disambiguated `City (Region)` label while the update
  controller only matches a raw city name. DES-05 retains the existing text
  field instead of introducing an unreliable autocomplete.
- The backend provides no completion value, photo order field, or photo reorder
  endpoint. DES-05 must not fabricate any of them.

## Profile completeness

Completeness is a deterministic client calculation over five documented,
saved fields. Each completed step is worth exactly 20 points:

1. a photo marked `is_avatar` (20%);
2. a non-empty biography (20%);
3. at least one saved interest (20%);
4. a non-empty saved city (20%);
5. a non-empty saved `what_looking_for` attribute (20%).

The card shows the percentage, completed-step count, and only the first missing
step in the order above. Its action opens the matching edit section. At 100%
the card becomes a calm completed state and has no warning CTA. This value is
not sent to the backend and is never described as a ranking or popularity
score.

## Editing architecture

Editing is one scrollable route with sections for basic information, city,
biography, interests, profile attributes, and photos. This matches the current
GoRouter/Riverpod architecture and keeps a single explicit Save action.

`CurrentProfileState` remains canonical. `EditProfileDraftState` contains a
baseline snapshot plus editable values. Text input only updates the draft; it
does not call an API. Photo mutations are separate immediate server operations
because the existing API does not include photos in `/user/update_user`.

Dirty state is computed by comparing the draft with its current canonical
baseline. Back navigation without changes exits directly. Dirty Back presents:

- Save changes;
- Discard changes;
- Keep editing.

The draft remains in memory across lifecycle pause/resume. No background Save
is attempted.

### Save sequence and partial failure

One guarded Save performs only changed logical sections, in this order:

1. `PUT /user/update_user` for supported basic fields;
2. `POST /interest/add_interests` for the complete selected ID list;
3. `POST /attributes/add_attributes` for changed attribute values;
4. canonical profile reload.

The endpoints are not transactional together. If a later step fails, the
client attempts a canonical reload, adopts any already persisted server data,
keeps the intended draft, and reports which part did not finish. Save becomes
available again. It never reports global success for a partial result. A busy
guard prevents double Save.

Field errors are local for blank required fields and non-integer height.
Backend validation details are mapped when a field can be identified; unknown
network/server failures remain an inline form error and never erase the draft.

## Interests and attributes

Interests are loaded from `GET /interest/interests_list`; production options
are not hardcoded. Selected and unselected chips include an explicit semantics
state and a 48 px touch target. The backend has no count limit, so DES-05 does
not invent a maximum or disable valid catalog items.

Attribute dropdown labels come from the UI, while their choices and submitted
values come from `GET /attributes/`. The visible `description` is also the
Pydantic enum value accepted by the backend. Technical enum `name` values are
not presented to users.

## Photos

### Upload

The existing gallery `ImagePicker` is reused; no camera permission or new
platform package is added. Cancel is a no-op. The current Flutter compatibility
guard accepts JPG/JPEG, PNG, and WebP, validates their signatures, and limits a
selected file to 10 MiB before upload. The backend itself accepts JPEG, PNG,
GIF, BMP, TIFF, WebP, HEIC, and HEIF by MIME inspection, but currently declares
no byte-size or photo-count limit. The UI describes the stricter active client
pipeline accurately.

`POST /service/upload/profile_photo?is_avatar=...` receives multipart data.
The first photo is uploaded as avatar. Progress and failure belong only to the
photo manager; the rest of the profile remains usable. One failed file may be
retried, and an in-flight upload cannot be duplicated. After success the client
reloads canonical profile and photo state.

### Delete

`DELETE /user/photos/{photo_id}` is preceded by confirmation. The message calls
out an avatar or last photo. The backend has no minimum photo count, so deleting
the last photo is allowed rather than blocked by a fabricated rule. On failure
the original item stays visible and offers a clear retry path.

If the deleted photo was the avatar and photos remain, the client uses the
existing `POST /user/set_avatar/{photo_id}` endpoint to make the first photo in
the canonical response primary. If no photos remain, the profile has no
primary photo.

### Primary photo

`is_avatar` is the only primary-photo mechanism. A user can explicitly call
`POST /user/set_avatar/{photo_id}`. The operation is serialized, and the
canonical response replaces local state.

### Reorder

Reorder is not implementable against the current immutable contract:

- `UserPhoto` has no order column;
- photo responses have no order field;
- queries define no stable `ORDER BY`;
- no reorder endpoint exists.

DES-05 therefore exposes no drag gesture, left/right controls, or local-only
order, because all would revert after reopening and violate the task's source
of truth. Adding persisted reorder requires a separate backend-contract and
migration task. This is a known acceptance gap, not a simulated feature.

## Own profile presentation

The profile tab uses the Midnight Aura backdrop, a floating glass top bar, and
the existing floating navigation. Content sections are solid/translucent,
without per-section blur. At most the top bar and navigation are active blur
regions. The primary image is bounded and decoded at thumbnail/display size.

The screen contains real identity, city, biography, interests, goal and other
non-empty attributes, photos, completion, current Subscription entry, Edit,
saved-profile Preview, and Settings. Empty optional content becomes a specific
edit affordance rather than fake filler.

Initial load uses skeletons. Initial failure keeps navigation and exposes
Retry. A refresh error with retained data is inline. Scroll state uses the
profile tab's page-storage key and is preserved when Subscription or Settings
is pushed and popped.

## Preview and navigation

Routes are unique:

- `/profile` — own profile tab;
- `/profile/edit` — draft editor;
- `/profile/preview` — saved current profile rendered by the existing
  `PublicProfileView`/`ProfileHero`/`ProfilePhotoGallery` components;
- `/premium` — existing DES-04 Subscription screen;
- `/settings` — existing Settings screen.

Preview contains no reaction or safety actions and explicitly represents the
latest saved canonical profile, never an unlabelled draft. Save updates the
shared profile provider before returning, so the own profile and preview change
without restarting. The navigation shell currently uses a generic profile icon
rather than a user avatar, so there is no separate navigation-avatar cache to
synchronize.

The profile provider observes authenticated user identity. Logout/login resets
its state and prevents one user's profile from being retained for another.

## Accessibility and performance

- all Edit, Preview, Settings, Save, Add, Delete, Retry, and Make primary
  controls have semantics and at least 48 x 48 logical-pixel targets;
- selected interest and primary-photo states are communicated by text/icon and
  semantics, not color alone;
- layouts scroll at 1.3 text scale, on compact devices, and with long content;
- high contrast uses existing semantic tokens;
- transitions respect `MediaQuery.disableAnimationsOf(context)`;
- photo thumbnails request bounded cache dimensions and use stable photo IDs;
- text controllers are created once and disposed by the edit screen;
- image upload, delete, primary selection, and Save each reject duplicate
  concurrent requests;
- no media path, token, authorization header, or signed URL is logged.

There is no reorder gesture to provide an accessibility alternative for until
the backend supports persisted ordering.

## Test matrix

Widget and state tests cover loading, complete/incomplete/error profile,
retry, missing/one/multiple photos, subscription states, deterministic
completion, navigation callbacks, long content, 1.3 text scale, initial draft,
dirty/no-change behavior, validation, guarded Save, error-preserved draft,
discard/keep-editing, catalog enum mapping, picker cancel, upload progress and
error/retry, delete confirmation and failure, primary update, and saved preview
without public actions.

Golden scenarios cover own profile complete/incomplete/loading/error/missing
photo, edit normal/validation/saving/upload state, and saved preview. Tests use
fakes and deterministic in-memory images only. Persisted photo reorder and
server maximum/minimum tests are intentionally blocked by the missing backend
contract described above.
