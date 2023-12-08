# 14. Find to last read a message

Date: 2023-12-5

## Status

Accepted

## Context

In the room, we have a lot of messages. When we open the room, we need to find the last read
message.

## Decision

The user’s fully read marker is kept as an event in the room’s account data.
It is different for each user in group.
The event may be read to determine the user’s current fully read marker location in the room,
and just like other account data events the event will be pushed down the event stream when updated.

The fully read marker is kept under an `m.fully_read` event. If the event does not exist on the
user’s account data,
the fully read marker should be considered to be the user’s read receipt location.

In MatrixSdk we can use `fullyRead` to get the last read message.

```
  /// ID of the fully read marker event.
  String get fullyRead =>
      roomAccountData['m.fully_read']?.content.tryGet<String>('event_id') ?? '';
```

## Docs

https://spec.matrix.org/v1.9/client-server-api/#events-6