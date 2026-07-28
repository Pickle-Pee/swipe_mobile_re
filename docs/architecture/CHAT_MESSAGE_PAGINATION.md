# Chat message pagination

`CHAT-PAG-01` replaces Socket.IO history transfer with a bounded REST contract.
The backend OpenAPI route is the source of truth.

## Transport split

```text
GET /communication/{chat_id}/messages -> message history
Socket.IO join_chat                   -> compact room acknowledgement
Socket.IO new_message/completer/...   -> realtime changes only
Flutter controller                    -> deterministic merged timeline
```

The initial request is:

```http
GET /communication/{chat_id}/messages?limit=30
```

Older pages pass the opaque `next_cursor` back as `before`:

```http
GET /communication/{chat_id}/messages?limit=30&before=<cursor>
```

The response is:

```json
{
  "items": [],
  "next_cursor": "opaque-or-null",
  "has_more": false
}
```

Items are ordered oldest to newest inside every page. The client never parses
the cursor and never uses an offset. The repository limit is 30; the backend
allows 1 through 100.

## State and merge rules

The existing Riverpod controller owns:

- `initialLoading` and initial `error`;
- `isLoadingOlder` and `loadOlderError`;
- `hasMore` and `nextCursor`;
- the merged message list and `isSending`.

The controller loads the newest REST page when the conversation opens. Reaching
the top threshold requests one older page at a time. Older items are prepended,
then the scroll offset is compensated by the change in scroll extent so the
same visible message stays anchored.

One state can contain REST rows, realtime rows, optimistic sends, failed sends,
and acknowledgements. Merge priority is server message id, then external/local
id, then a narrow optimistic fallback for a missed acknowledgement. Ordering is
stable by `(created_at, message_id/local_id)`. A server row never creates a
second copy of an acknowledged or pending message.

## Reconnect

On socket authentication the open conversation emits `join_chat`. A reconnect
requests only the newest REST page and merges it into the existing state; it
does not discard already loaded older pages or pending/failed messages. The chat
list is refreshed once so unread counts for inactive conversations come from
the backend. Socket.IO never requests or receives full history.

## Compatibility

The active `features/chat` flow no longer references `get_messages`. The
backend temporarily answers an old request with `history_deprecated` and no
message array for external compatibility. DES-08 removed the orphaned
MobX/socket client, so Flutter now has no producer, listener, model, or test
path for socket history.

Text, image, and voice history fields keep their existing rendering behavior.
Only text sending is exposed by the current composer.
