# Midnight Aura chats specification

## Scope and sources of truth

DES-03 redesigns the existing chat list and conversation presentation without
changing backend endpoints, Socket.IO event names, authentication,
subscriptions, or Match semantics. The existing REST/OpenAPI implementation
and Socket.IO handlers remain the source of truth.

The active Flutter flow uses:

```text
GET  /communication/get_chats
GET  /communication/{chat_id}
GET  /communication/get_chat_id_by_user_id?recipient_id={user_id}
POST /communication/create_chat { "user_id": user_id }

Socket.IO:
authenticate -> auth_response
get_messages -> get_messages
send_message -> completer
new_message
message_delivered
message_read
message_status_update
all_messages_read
error
```

The application keeps one authenticated socket manager for the app lifetime.
A conversation subscribes to that manager once and cancels only its stream
subscription on dispose. The backend has no explicit join/leave-room event;
the active conversation is client UI state, not a new protocol concept.

## Contract reality

`GET /communication/get_chats` returns the server/repository order and has no
pagination parameters. Each summary contains a real chat id, other user,
avatar, chat creation time, last-message preview, unread count, and optional
last-message sender/status/type. DES-03 preserves that order. An incoming
message moves its existing chat to the top once; unknown chats trigger a
single refresh instead of creating synthetic rows.

The only list timestamp currently contracted is `created_at` for the chat.
There is no `last_message_at`. The UI may format the real available timestamp,
but must not label it as a fabricated last-message time. A future backend
contract can replace it without changing the visual component.

`get_messages` returns the complete ordered history and has no cursor, offset,
or end marker. DES-03 therefore does not show a fake bottom loader or claim
pagination. The list remains lazy, keyed, and scroll-position aware; true
history pagination requires a separate backend-contract task.

The backend payload can describe text, image, and voice records. The active
Riverpod send path is complete only for text. Image/voice upload methods and a
voice model still exist in the legacy MobX layer, but the production composer
does not own a media picker, recorder, or audio player. DES-03 therefore:

- fully renders, sends, acknowledges, retries, and statuses text messages;
- does not expose attachment or voice controls that are not wired to the
  active flow;
- renders incoming image history in a bounded bubble with a deterministic
  fallback, without implying that image sending is active;
- treats voice and unknown history defensively without inventing playback,
  waveform, upload, or full-screen media flows.

## Chat list structure

```text
static Midnight Aura backdrop
-> SafeArea
-> one compact glass ChatsTopBar
-> loading / empty / error / real chat list
-> existing floating shell navigation
```

The top bar contains the title and optional aggregate unread count derived
only from loaded `ChatSummary.unreadCount` values. It is one backdrop region.

`ChatListTile` is a solid, non-blurred Material row with:

- a bounded avatar and deterministic missing-avatar fallback;
- one-line name with ellipsis;
- last-message preview on at most two lines;
- formatted real timestamp when available;
- unread badge only when `unreadCount > 0`;
- delivery/read state only for a last message sent by the current user and
  only when the response supplied that state;
- a minimum 48 logical-pixel target, pressed feedback, and one complete
  semantics label.

No row shows user `status`: the current backend value is not a reliable
presence contract. There is no fake online, typing, compatibility, AI summary,
last message, or unread count. `BackdropFilter` is forbidden in rows.

## Chat list states

| State | Presentation | Action |
| --- | --- | --- |
| first load | solid skeleton rows without names or copy | none |
| data | server-ordered rows | open, pull to refresh |
| empty | quiet explanation that chats follow mutual matches | Discover |
| first-load error | solid error state with concise safe copy | Retry |
| refresh error | existing rows stay visible; retry remains available | Retry |

Reload deduplicates by chat id. Realtime deduplicates by server message id or
client local id and bounds the in-memory seen-id set. Unread values are clamped
to zero or above.

## Conversation structure

```text
static Midnight Aura backdrop
-> SafeArea top
-> one glass ChatTopBar
-> optional solid ConnectionBanner
-> lazy MessageList
-> optional ScrollToBottomButton
-> one glass ChatComposer in bottom SafeArea
```

`ChatTopBar` shows Back, the real avatar fallback, and the real first name.
Avatar/name opens the existing public-profile route. It does not render the
backend `status` as online/last-seen. Invalid or failed chat details produce an
explicit retryable state.

The message list uses one persistent `ScrollController`, stable server/local
keys, and day separators. It scrolls after the first history load, after the
current user sends, or when the user is already near the bottom. Incoming
messages do not force the user away from older history; a compact button
returns to the bottom instead.

## Text message bubble and status

Message bubbles use solid/translucent paint and no blur. Own messages use a
restrained rose/violet tint; incoming messages use `surfaceSolid`. Bubble width
is responsive rather than a fixed phone width, text keeps readable line
height, and the timestamp/status occupy one compact metadata row.

Own-message states are:

| State | Meaning | UI |
| --- | --- | --- |
| sending | emitted locally, awaiting `completer` | subtle progress/status |
| sent | backend acknowledged | sent indicator |
| delivered | backend reports delivery | delivered indicator |
| read | backend reports read | read indicator |
| failed | explicit socket send error | error + Retry |

`completer` replaces the optimistic record by matching
`external_message_id`; history and realtime merge by server id or local id.
An explicit send error marks the visible optimistic message failed. Retry
reuses that local record and cannot be double-tapped. The client does not retry
an acknowledgement timeout blindly because the current backend does not
persist an idempotency key; doing so could duplicate a message after a lost
acknowledgement.

## Composer and keyboard

`ChatComposer` is the conversation's second and final backdrop region. It has
one `BackdropFilter`, a multiline input that grows to a bounded height, and a
48 logical-pixel Send target. Send is disabled for blank input, an in-flight
send, or a disconnected socket. The controller and UI both guard double send.
The input remains usable while offline so the user can edit text, but the UI
does not promise durable offline delivery.

SafeArea and the Scaffold's normal keyboard insets keep the composer visible.
Android Back dismisses the keyboard first; subsequent Back pops to the
preserved chat list when possible, otherwise it navigates to `/chats`.

## Connection and reconnect states

The socket manager exposes `connecting`, `connected`, `reconnecting`,
`offline`, and `failed` from real transport/auth events. The conversation only
shows a compact banner when the state is not connected and uses user-facing
copy without protocol details.

Listeners are bound once in the manager constructor and removed on manager
dispose. Reconnect reauthenticates the same transport, requests active history
again, and merges rather than appends duplicates. Pending commands remain
in-memory only for the current process. Logout clears them and disconnects.

## Unread rules

- REST `unread_count` initializes list and shell badges.
- An incoming message increments its inactive chat once.
- An incoming message for the active chat keeps its unread count at zero and
  emits the existing delivered/read events.
- Opening a conversation immediately clamps its local unread to zero, then
  marks real incoming history ids through the existing Socket.IO protocol.
- Replayed reconnect events do not increment again because message ids are
  deduplicated.
- No badge is hardcoded and no count may become negative.

## Dates and timezone

All parsed values are converted to local time for display. Summary formatting
uses local time today, `Yesterday`, then a compact date. Conversation history
uses day separators and local time without exposing ISO strings. The existing
Flutter SDK formatting is sufficient; DES-03 adds no package solely for dates.

## Routing

```text
Match -> ChatListController.openOrCreate -> /chat/{real_chat_id}
Chat list -> push /chat/{real_chat_id}
Chat avatar/name -> push /discover/profile/{real_user_id}
Profile Back -> same conversation
Chat Back -> preserved chat list, or /chats fallback
```

There is one chat route and one provider family keyed by the real integer chat
id. Switching chats disposes the previous conversation subscription and
controller resources. No backend or Match semantics change.

## Accessibility and motion

- Text scaling is unrestricted and verified at 1.3.
- Long names/previews/messages ellipsize or wrap without moving critical
  controls off-screen.
- Back, chat row, profile, Send, Retry, and scroll-to-bottom expose semantics.
- All interactive targets are at least 48 logical pixels.
- High contrast strengthens solid borders and message separation.
- Reduced motion removes non-essential appearance and press durations.
- Focus order follows top bar, history, composer, Send.

Row press uses 140 ms feedback, connection changes and message appearance use
up to 220 ms, and no list-wide, bouncing, or infinite animation is introduced.

## Performance budget

- Chat list: one top-bar blur plus the existing one navigation blur.
- Conversation: one top-bar blur plus one composer blur.
- Zero backdrop filters inside either lazy list.
- Stable message keys and `RepaintBoundary` around media/fallback regions.
- One persistent scroll controller and one conversation stream subscription.
- State changes merge only affected records; no full-screen ticker exists.
- The current API has no pagination, so history remains an acknowledged memory
  risk for very long chats until a backend cursor contract is introduced.

## Test scenarios

Widget/provider/socket tests cover loading, data, empty, error/retry, unread and
no-unread, long content, missing avatar, row navigation, text scale 1.3, compact
viewport, history loading/empty/error, day separators, own/incoming text,
pending/failed/retry, disabled Send, double-send protection, incoming merge,
reconnect deduplication, Back, profile navigation, and scroll behaviour.

Deterministic goldens cover:

```text
Chats normal
Chats unread
Chats empty
Chats error
Chat normal
Chat long messages
Chat image receive
Chat offline
Chat send error
Chat expanded composer
```

The image golden covers the supported receive-only presentation. A voice
golden is intentionally excluded until an active player exists. Golden
MediaQuery disables animations and no test contacts production services.
