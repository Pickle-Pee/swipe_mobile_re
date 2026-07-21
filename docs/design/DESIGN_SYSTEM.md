# Midnight Aura Glass design system

Midnight Aura Glass is a dark, media-first visual system. Glass communicates
navigation or temporary controls; it is not the default content background.
The system is implemented with semantic tokens so contrast and effect budgets
can evolve without screen-specific colour constants.

## Semantic palette

| Role | Value | Use |
| --- | --- | --- |
| background base | `#090A0F` | app and fallback background |
| background elevated | `#11131B` | raised regions |
| surface solid | `#171923` | ordinary content without blur |
| glass low | white 6% | subtle overlay fill |
| glass medium | white 10% | navigation fill |
| glass active | white 16% | selected/pressed fill |
| glass border | white 14% | normal glass edge |
| glass highlight | white 26% | sparing high-contrast edge |
| text primary | `#F7F7FA` | names and headings |
| text secondary | `#F7F7FA` at 68% | supporting copy |
| text muted | `#F7F7FA` at 44% | tertiary labels |
| brand rose | `#FF4F7B` | primary action start |
| brand violet | `#8B6CFF` | primary action end |
| success | `#62D7A8` | successful semantic state |
| warning | `#FFBF69` | warning semantic state |
| error | `#FF6B7A` | error semantic state |

Rose and violet form one brand axis. Success, warning, and error are reserved
for their meanings and do not become decorative peers.

## Typography

The project has no bundled Manrope asset. DES-01 retains the platform sans-serif
font to avoid a new runtime dependency, using the closest supported Flutter
weights. Flutter does not expose weight 650, so title and button styles use 600.

| Token | Size / height / weight |
| --- | --- |
| display | 36 / 40 / 700 |
| headline | 28 / 32 / 700 |
| title large | 22 / 28 / 600 |
| title | 17 / 22 / 600 |
| body | 15 / 21 / 500 |
| caption | 12 / 16 / 500 |
| button | 15 / 18 / 600 |

Text over media always sits over a dedicated black readability gradient. Heavy
per-character shadows are not part of the system.

## Spacing and geometry

Spacing tokens are 4, 8, 12, 16, 20, 24, 32, and 40 logical pixels. Screen
horizontal padding is 16 on compact layouts and 20 when space permits.

Radii are 12 (small), 18 (medium), 26 (large), 32 (extra large), and 999
(pill). All interactive controls have a minimum 48 x 48 target. Standard action
buttons are 56 high; compact icon controls remain 48 square.

## Surfaces and borders

Ordinary content uses `surface solid` or a non-blurred translucent variant.
Borders use glass border on dark glass and a lower-opacity white edge on solid
surfaces. A one-pixel highlight may be used on a primary floating region.

Shadows are dark, soft, and structural. Brand-coloured glow is limited to the
Like/primary action and must remain low opacity. Cards do not receive multiple
stacked shadows.

## Glass levels

`GlassLevel` is semantic rather than numeric:

| Level | Fill | Blur | Border | Intended use |
| --- | ---: | ---: | ---: | --- |
| navigation | white 10% | 18 | white 14% | floating tab navigation |
| overlay | white 8% | 12 | white 12% | grouped controls over media |
| sheet | white 14% | 24 | white 16% | modal profile/details sheet |

Glass is clipped before blur. A screen may show at most three backdrop regions;
the normal Discovery composition uses two: top controls and navigation. Opening
the details sheet adds one temporary sheet region. Buttons, tags, media, error
messages, and list items use solid/translucent paint without backdrop blur.

Never nest glass, put it in a long list, or use it for every text block.

## Gradients

The only vivid action gradient is `#FF4F7B -> #A45CFF` and belongs to the
primary action. The background uses near-black rose/violet aura fields that do
not compete with profile photography. Media readability uses transparent black
to opaque black and is independent of brand colour.

## Icons and controls

Icon sizes are 18 (compact/supporting), 22 (standard), 24 (navigation), and 28
(prominent action). Icons never reduce their tap target below 48.

Primary action states:

- enabled: rose-to-violet fill, primary text/icon, restrained shadow;
- pressed: scale 0.98 for 120-160 ms and reduced glow;
- disabled: solid muted surface, muted content, no glow;
- loading: fixed button geometry, labelled progress indicator, input blocked.

Secondary action states use a solid translucent surface and visible border. They
share the same pressed, disabled, loading, and double-submit rules. Progress is
specific to the action that initiated it.

## Motion

| Interaction | Duration |
| --- | ---: |
| press feedback | 140 ms |
| tab selection | 200 ms |
| content fade | 220 ms |
| profile transition | 300 ms |
| modal sheet | platform spring |

There are no looping glows, bouncing navigation items, or full-screen tickers.
When `MediaQuery.disableAnimationsOf(context)` is true, decorative durations
become zero and only state-essential changes remain. Golden tests disable
animation.

## Accessibility

- Body content maintains readable contrast against dark solid surfaces.
- The media scrim is strengthened in high-contrast mode.
- Selection is conveyed by label weight, fill, and indicator, not colour alone.
- Icon-only controls expose explicit semantic labels.
- Reading/focus order follows top controls, identity, details, Pass, Like, then
  shell navigation.
- Layouts support text scale 1.3 without clipping and do not disable system text
  scaling.
- Loading indicators have textual semantics, and errors expose a retry action.

## Performance budget

- Normal Discovery: two visible `BackdropFilter` regions maximum.
- Details open: three visible regions maximum.
- No backdrop filter in repeated/list content.
- No continuously ticking full-screen background.
- Profile media is isolated by `RepaintBoundary`.
- Profile switches animate only opacity/scale of the card region.
- Image loading uses bounded layout and a deterministic missing/error fallback.

Profile mode should be checked on an Android device or emulator. Look for raster
spikes during the first image decode, profile transition, modal sheet, and tab
switch; document any environment that prevents this check.

## Image rules

- Profile media is the largest Discovery object and uses `BoxFit.cover`.
- Remote URLs are resolved through configured `REST_API_URL`; no screen hardcodes
  a service host.
- Missing or failed media uses the same dark branded placeholder and an explicit
  semantic label. No stock person or invented profile data is substituted.
- Identity text has its own readability gradient for both dark and light photos.
- Image widgets keep stable bounds while loading to prevent layout shift.
