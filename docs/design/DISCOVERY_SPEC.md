# Midnight Aura Discovery specification

## Product path and contract

Discovery remains a presentation of the existing backend flow:

```text
GET /match/find_matches
-> GET /user/{id} enrichment
-> show current profile
-> POST /likes/like/{id} or POST /likes/dislike/{id}
-> advance only after success
-> show match handoff when backend returns "It's a match!"
```

No route, request, repository endpoint, auth rule, chat flow, subscription rule,
or reaction meaning changes in DES-01.

Only real model data is rendered: first name, derived age, city, about text,
avatar, up to three interests, and available attributes. Distance and verified
state are omitted because they are not stable fields in the current OpenAPI
response. Match percentage is deliberately not shown.

## Screen structure

```text
full-screen profile media
-> one grouped glass top-control region
-> media readability gradient
-> identity block
-> up to three compact interest tags
-> details button and modal profile-details sheet
-> Pass and Like action controls
-> floating shell navigation
```

The media card fills the screen area between safe insets and floating
navigation. It is not placed inside a white content card. The lower gradient is
strong enough to protect text against light photography and becomes stronger in
high-contrast mode.

The top region contains the Discovery label, Likes, and Chats. It is one glass
region, not separate nested glass buttons. Likes and Chats preserve the current
tab routes.

The identity block shows a single-line name/age heading, city when non-empty,
and the first three non-empty interests. A labelled details button opens a modal
sheet containing only already-loaded profile data: full interest list, about
text, and non-empty attributes. It does not duplicate profile fetching or edit
logic.

## Actions

Like is the only vivid CTA. Pass is neutral. Both are at least 56 high with
explicit labels, pressed scale feedback, disabled/loading states, and semantic
button descriptions.

The controller remains the source of double-submit protection. Presentation
tracks the in-flight reaction so only Like shows Like progress and only Pass
shows Pass progress; both controls are unavailable until the request resolves.
On an API failure, the profile stays visible, controls become available again,
and an inline error with Retry is shown.

## State matrix

| State | Presentation | Available action |
| --- | --- | --- |
| initial/loading | static media-shaped skeleton; no looping shimmer | none |
| data | profile media, identity, details, Pass, Like | all valid actions |
| no profiles | solid empty state: no profiles nearby now | reload |
| end of feed | solid completion state after last successful reaction | reload |
| initial API error | error state with concise backend-safe message | retry |
| data + API error | current card retained plus inline error | retry/reaction |
| missing image | dark aura placeholder and person outline | details/Pass/Like |
| Like in progress | Like-labelled progress; both reactions blocked | none |
| Pass in progress | Pass-labelled progress; both reactions blocked | none |

Remote image failure uses the same missing-image state. It does not remove the
profile or synthesize media.

## Navigation shell

The four existing branches remain Discover, Chats, Likes, and Profile inside
`StatefulShellRoute.indexedStack`. The floating navigation observes SafeArea,
sits above the system edge, and does not recreate inactive branches. Selecting
the active tab returns that branch to its initial route as before.

Chat badge content may only come from summed `unreadCount` values already held
by `ChatListController`; no placeholder badge is rendered. System Back from a
secondary tab returns to Discover before leaving the shell. The Discovery card
reserves enough bottom space that the navigation never covers its actions.

## Motion and accessibility

- Card changes use a 220-300 ms fade/very small scale transition.
- Tab state changes use 200 ms colour/indicator transitions.
- Press feedback scales to 0.98 for 140 ms.
- Reduced motion sets decorative transition durations to zero.
- High contrast strengthens media scrim, control fill, and borders.
- Every icon action has a semantics label and 48 x 48 target.
- Long names ellipsize on one line without moving action controls.
- Text scale 1.3 and a 320 x 568 logical-pixel viewport remain overflow-free.

## Effect and repaint budget

Normal visible blur regions:

1. grouped Discovery top controls;
2. floating shell navigation.

Opening profile details temporarily adds the sheet as region three. Media,
tags, action buttons, skeletons, empty/error states, and inline messages do not
blur the backdrop. Profile media is wrapped in a `RepaintBoundary`; the static
backdrop does not tick or rebuild each frame.

## Test contract

Widget coverage exercises loading, data, initial empty, end-of-feed copy,
initial error/retry, inline reaction error, missing/failed media, Like loading,
Pass loading, double tap protection, details opening, navigation selection,
long name, text scale 1.3, and compact viewport.

Deterministic goldens cover normal, loading, empty, error, long content, and
missing image. Tests use a deterministic in-memory image provider and disable
animations; they never call the network.
