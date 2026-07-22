# Discovery UI audit

Audit date: 22 July 2026

Branch: `codex/design-midnight-aura-discovery`

Scope: Flutter application shell, navigation, Discovery, its data flow, and the
backend fields consumed by that flow. Backend code is read-only for DES-01.

## Sources inspected

- workspace instructions: root `AGENTS.md`, `docs/SUBSCRIPTION_CONTEXT.md`;
- repository instructions and context: Flutter `AGENTS.md`, `docs/BASELINE.md`,
  subscription contract/handoff; backend `AGENTS.md`, `docs/PROJECT_CONTEXT.md`,
  and `docs/BASELINE.md`;
- application composition: `app.dart`, `app_router.dart`, `routes.dart`, and
  `main_shell.dart`;
- visual foundation: `tokens.dart`, `app_theme.dart`, `liquid_ui.dart`,
  `glass_tabbar.dart`, `animated_liquid_background.dart`, and
  `shader_liquid_layer.dart`;
- Discovery: screen, Riverpod controller, domain models, Dio repository, and
  provider/repository tests;
- adjacent UI state: profile, likes, and chat screens, models, repositories,
  providers, and tests;
- backend contract implementation: match, user, and likes controllers; user,
  likes, interests, and verification models/schemas; demo flow and distance
  tests.

Flutter has no `docs/PROJECT_CONTEXT.md`; `docs/BASELINE.md` is its current
general project context.

## Current architecture

`MaterialApp.router` uses a Riverpod-provided `GoRouter`. The four production
tabs live in a `StatefulShellRoute.indexedStack`, which already preserves each
branch rather than recreating it on every switch. `MainShell` overlays
`GlassTabBar` on the selected branch.

`DiscoveryScreen` watches `DiscoveryController`. The controller loads profiles
through `DiscoveryRepository`, prevents a second reaction while one is in
flight, advances the feed only after a successful request, and exposes a mutual
match once. The repository calls:

- `GET /match/find_matches`;
- `GET /user/{id}` for each returned match;
- `POST /likes/like/{id}`;
- `POST /likes/dislike/{id}`.

The screen currently owns loading, empty, error, card, action, match dialog,
and three additional navigation shortcuts. This mixes state presentation,
profile composition, and navigation chrome in one file.

## Contract reality

The usable profile fields are id, first name, date of birth, city, about text,
avatar URL, interests, and non-empty profile attributes. Discovery has no
contracted distance field. The match endpoint currently returns an empty
interest list, but the existing `/user/{id}` enrichment supplies interests.

The backend controller passes `verify` while constructing `UserDataResponse`,
but that response schema does not declare the field. It is therefore not part
of the OpenAPI contract and may be filtered from the response. Discovery must
not render a verified badge until the backend contract exposes a stable field.
There is no subscription restriction in the current Discovery controller.

## Visual and hierarchy problems

- The primary media is constrained to a 220 px strip inside a white translucent
  card, so the person is not the dominant visual object.
- Name, biography, interests, and attributes compete at the same hierarchy
  level. There is no dedicated readability gradient over the photo.
- Discovery duplicates navigation below the card even though the shell already
  supplies four tabs.
- Like and Pass are visually similar in size; the three-colour CTA gradient
  gives several accents equal weight.
- The navigation contains a hard-coded chat badge (`34`), which is not product
  data.
- Fixed heights and scattered literal spacing/radii make long names, text scale,
  and compact screens fragile.

## Colour, contrast, and glass problems

- `AppTokens.surface` and `surfaceStrong` are 70% and 85% white, while the theme
  still describes itself as dark. The result is bright frosted cards rather
  than a dark premium surface system.
- Primary text is nearly black and secondary text is grey because the current
  surfaces were designed around white cards. These values are unsuitable for
  direct placement on dark media.
- `GlassSurface` always creates a `BackdropFilter`; it has no semantic level or
  way to request a solid/translucent surface.
- The same glass primitive is used for cards, lists, bubbles, navigation, and
  content, so blur cost and visual importance are not controlled.
- The CTA uses rose, violet, and blue; other components additionally introduce
  cyan and mint as peers.

## Performance problems

- Both `MainShell` and branch screens can paint an `AppGradientScaffold`,
  duplicating atmosphere and vignette layers.
- `AiAtmosphericBackground` owns a ticker and calls `setState` every frame. Its
  painter draws four screen-scale circles with mask-filter blur values from 260
  to 340 logical pixels.
- Every `GlassSurface`, including surfaces in scrolling production screens,
  incurs backdrop blur. There is no on-screen blur budget.
- The media card has no explicit repaint isolation.
- The shader alternative also ticks and repaints continuously and is not needed
  for the Discovery result.

## Accessibility problems

- The old navigation and Discovery shortcuts do not consistently guarantee a
  48 x 48 logical-pixel target.
- Icon-only actions do not all have explicit screen-reader labels.
- The fixed media height and dense content can overflow at text scale 1.3 or on
  a small screen.
- Loading only changes button copy and does not identify which reaction is in
  progress.
- Colour and glow carry too much selection emphasis. High contrast and reduced
  motion are not consulted by the visual components.
- The profile image has no useful semantic description or explicit missing-image
  state.

## Reuse and replacement plan

Reuse without changing product semantics:

- `StatefulShellRoute.indexedStack` and all existing route paths;
- `DiscoveryController`, repository calls, real model mapping, reaction guard,
  and mutual-match handoff;
- chat unread counts when they have actually been loaded;
- API error mapping and media URL resolution.

Replace or extend for DES-01:

- replace the animated multi-blur background in the active shell/Discovery path
  with a static, repaint-isolated Midnight Aura backdrop;
- replace white defaults with semantic dark tokens and three explicit glass
  levels;
- replace `GlassTabBar` in the shell with one floating
  `GlassNavigationBar`, while retaining a compatibility wrapper;
- split Discovery presentation into media, readability overlay, details sheet,
  action bar, and reusable state components;
- distinguish Like and Pass progress in UI state without changing repository
  behaviour;
- distinguish an initially empty feed from the end of a consumed feed;
- add deterministic widget and golden coverage; the repository currently has no
  golden-test infrastructure.

## Production logic that must not change

- backend code, OpenAPI paths, request bodies, and response interpretation;
- authentication and session restoration;
- Like maps to `/likes/like/{id}` and Pass maps to
  `/likes/dislike/{id}`;
- a card advances only after a successful reaction;
- double reaction requests remain blocked;
- mutual match navigation continues to open the existing Chats flow;
- all existing shell routes and stateful branch preservation;
- chat, subscription, profile editing, and payment business logic.
