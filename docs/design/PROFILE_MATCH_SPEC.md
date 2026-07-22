# Midnight Aura public profile and mutual match specification

## Scope and source of truth

DES-02 extends the existing Midnight Aura Glass system to the full profile of
another user and to the mutual-match moment. It does not redesign the current
user's profile, profile editing, Likes, the chat list, chat messages,
subscriptions, onboarding, registration, or settings.

The backend OpenAPI implementation remains the source of truth. This feature
uses the existing contract only:

```text
GET  /user/{id}
GET  /user/user/photos/{id}
POST /likes/like/{id}
POST /likes/dislike/{id}
GET  /communication/get_chat_id_by_user_id?recipient_id={id}
POST /communication/create_chat { "user_id": id }
```

`DiscoveryController` remains the only owner of Like/Pass progress,
double-submit protection, feed advancement, reaction errors, and mutual-match
detection. `ChatListController.openOrCreate` remains the only UI-level flow for
reusing or creating a chat. DES-02 does not introduce a second reaction or chat
controller.

## Contracted profile data

`GET /user/{id}` currently declares these fields:

- `id`;
- `first_name`, `last_name`;
- `date_of_birth`, from which age is derived locally;
- `gender`;
- `city_name`;
- `about_me`;
- `avatar_url`;
- `interests` with `interest_id` and `interest_text`;
- `attributes`: height, smoking attitude, alcohol attitude, children
  preference, relationship goal, appearance, and religion;
- `is_favorite`, `is_subscription`, `status`, and `match_percentage`.

`GET /user/user/photos/{id}` declares an ordered `photos` collection containing
`id`, `photo_url`, `is_avatar`, and optional crop metadata. The response order
is preserved; the avatar is preferred for the hero when present. Crop metadata
is retained as contract data but is not interpreted until the backend and all
clients agree on its coordinate semantics.

The public profile renders only meaningful product data: name, derived age,
city, gender, about text, interests, non-empty attributes, and real photos.
Empty values do not create sections. Enum-like values are converted to readable
labels and are never displayed as raw snake_case identifiers.

The following contracted values are deliberately not presented:

- `match_percentage`, because the current backend baseline returns a
  placeholder value and DES-02 forbids compatibility content;
- `status`, because the current data does not establish reliable activity
  semantics for the redesigned experience;
- `is_subscription`, because subscription presentation is outside this task;
- `is_favorite`, because favorite controls are outside this profile flow.

The backend controller attempts to pass `verify`, but `UserDataResponse` does
not declare it. A verified badge is therefore not rendered. Distance is also
absent from the response contract and is not invented.

The Like response contains only a message. There is no independent match id in
the current API. The matched user's real id is therefore the stable match-flow
identifier until `openOrCreate` returns a real `chat_id`; the UI must never
fabricate a match id.

## Routing and ownership

The existing `StatefulShellRoute.indexedStack` and tab locations remain
unchanged. Two non-tab routes are added:

```text
/discover/profile/:id
/match/:userId
```

Discovery opens the public profile route with the already loaded profile as an
optional route extra. Large models are never serialized into the URL. The id in
the path supports a direct route or a rebuilt route; the screen lazily refreshes
details and photos from the backend exactly once for that provider instance.

The profile route uses the existing Discovery provider for actions. It may act
only on the profile that is still current in the Discovery feed. A successful
non-match reaction returns to the current Discovery state, where the processed
profile is already absent. A failed reaction keeps the route open.

Mutual match is exposed by `DiscoveryController.matchedProfile`. The shell's
match coordinator consumes that one-shot value before navigating with `go` to
the full-screen match route. This prevents duplicate routes after rebuild and
removes the consumed public-profile route from the stack. App restart does not
reconstruct a consumed in-memory match event.

Match Back and Continue discovering both navigate to `/discover`. They never
return to an already processed public profile. Start chat remains on the Match
screen while resolving, then navigates to `/chat/{chatId}` using the real id.

## Public profile structure

The screen is a vertically scrolling, photo-first composition:

```text
hero photo
-> readability gradient and identity
-> one glass top-control region
-> solid identity/about content
-> optional real photo gallery
-> optional interests
-> optional profile facts
-> safe bottom clearance
-> floating ProfileActionBar
```

The hero occupies a substantial portion of the viewport and uses the same Hero
tag as the Discovery media. It has stable bounds, `BoxFit.cover`, a loading
skeleton, and the shared dark missing-media placeholder. A dedicated gradient
protects name and location against both light and dark images.

The top controls contain Back only. No report/block overflow is shown because
the current Flutter/backend flow does not implement those operations. Decorative
or non-functional menu items are prohibited.

All text sections use solid `surfaceSolid` regions without `BackdropFilter`.
Interests reuse `InterestChip` in a wrapping layout. Facts omit absent values
and present readable labels. A horizontally paged gallery has stable aspect
ratio, exposes every additional real photo, and does not place blur inside page
items.

## Profile states

| State | Presentation | Actions |
| --- | --- | --- |
| loading, no seed | stable hero/content skeleton | Back |
| loading with Discovery seed | seed content plus bounded loading progress | Back |
| data | full real profile and gallery | Back, Pass, Like |
| missing profile | explicit unavailable state | Back |
| initial error | error message and Retry | Back, Retry |
| refresh error with seed | retained profile plus inline error | Back, Retry |
| missing/broken image | shared branded placeholder | normal valid actions |
| Like/Pass loading | initiating action labelled loading; both disabled | none |
| Like/Pass error | profile retained and unobtrusive retryable error | Pass, Like, Retry |

Profile data does not shift when media starts loading. Network errors are mapped
to concise copy; backend payloads and technical exceptions are not displayed.

## ProfileActionBar

`ProfileActionBar` is one floating glass region above the system inset. It
contains neutral Pass and the single vivid Like action. It provides:

- minimum 48 x 48 logical-pixel targets and 56 logical-pixel button height;
- action-specific loading labels;
- disabled state for both controls during a request;
- existing pressed-scale feedback;
- one `BackdropFilter` for the entire grouped surface;
- keyboard, bottom inset, compact-screen, and SafeArea clearance;
- removal when the profile is no longer current.

The bar delegates to `DiscoveryController.like` and `.pass`; it never invokes
the repository directly.

## Mutual match experience

Match is a dedicated full-screen route rather than a bottom sheet. This gives
predictable Back behaviour, avoids nesting another sheet over the public
profile, and gives chat creation enough room for loading/error states.

The structure is:

```text
static Midnight Aura backdrop
-> close/back control
-> current user's real avatar or missing placeholder
-> matched user's real avatar or missing placeholder
-> match title and the other user's real name
-> primary Start chatting action
-> secondary Continue discovering action
```

The current user's photo is read from the existing `ProfileController`; the
controller is loaded on demand only if its real state is absent. The matched
photo comes from the consumed public-profile snapshot. Neither side uses a
stock person, fake profile, compatibility score, generated opener, or activity
status.

The reveal is finite: restrained aura fade, photo entrance, title fade, and
action fade over at most 700 ms. No controller ticks after the reveal. Reduced
motion replaces the sequence with a short opacity transition and no scale or
trajectory motion.

## Match actions and errors

Start chatting calls `ChatListController.openOrCreate(userId)`, which first
queries the existing-chat endpoint and creates only when absent. A local guard
and the controller's `isCreating` guard prevent duplicate requests. While the
operation is pending, both Match actions remain visible but Start chatting is
labelled as loading and cannot be pressed twice.

On success the screen opens `/chat/{chatId}`. On failure the Match route stays
open, shows a concise live-region error, and permits Retry or Continue
discovering. Match data is retained throughout the retry.

Continue discovering and system Back both go directly to current Discovery and
do not trigger a feed reload. Discovery already removed the processed profile
only after the successful Like response.

## Accessibility

- Text scaling remains system-controlled and is tested at 1.3.
- Long names, descriptions, many interests, and a 320 x 568 logical viewport
  must not overflow.
- Back, Pass, Like, Start chatting, Continue discovering, photos, gallery page
  position, and error retry expose explicit semantics.
- Focus order follows Back, identity/content, gallery, Pass, Like; Match follows
  Back, photo pair, title, Start chatting, Continue discovering.
- Media text always has a readability gradient; high contrast strengthens the
  scrim, borders, and action panel.
- Selection and loading are expressed by copy, icons, enabled state, and shape,
  never by colour alone.
- Reduced motion removes scale/trajectory reveal effects.

## Performance budget

The public profile has at most two active blur regions: the top controls and
the grouped ProfileActionBar. Content sections and gallery items are solid and
never use backdrop blur. The Match route also stays at two or fewer regions.

Hero media, paged gallery media, and the match photo pair use
`RepaintBoundary`. Images have bounded dimensions and are constructed lazily by
the page builder. There is no full-screen ticker or persistent glow animation;
finite controllers are disposed with their route.

Profile mode must inspect profile opening, first image decode, gallery paging,
vertical scroll, finite Match reveal, Match close, and chat navigation. Any
local Maven/cache limitation that prevents a profile build is reported rather
than replaced with debug-only performance claims.

## Test scenarios

Public-profile widget tests cover loading, normal real data, missing/one/many
images, empty optional fields, long name/description, many interests, Like,
Pass, both loading states, both error states, Retry, Back, text scale 1.3, and a
small viewport. No report-menu test is added because that product operation
does not exist.

Match widget tests cover real data, a missing second photo, Start chatting,
loading, error and retry, Continue discovering, system Back, repeated rebuild,
reduced motion, and a small viewport. Integration-level widget coverage follows:

```text
Discovery -> public profile -> Like -> mutual match
-> Match route -> open/reuse real chat route
```

The existing deterministic Discovery golden setup is reused for:

```text
Profile normal
Profile multiple photos
Profile missing photo
Profile long content
Profile error
Match normal
Match missing photo
Match chat error
```

Golden media uses deterministic in-memory providers and disables animations;
production code contains no static test profiles.
