# 13. Add a callback for when messages become visible or scroll out of view

Date: 2023-12-05

## Status

Accepted

## Context

- We have a lot of unread messages in the room.
- When we open the room, we need to set messages is read.

## Decision

- We use `visibility_detector` to detect when messages become visible or scroll out of view.
- We use `onVisibilityChanged` to listen callback when messages become visible or scroll out of
  view.

```
VisibilityDetector(
  key: Key(message.id),
  onVisibilityChanged: (visibilityInfo) {
    if (visibilityInfo.visibleFraction == 1.0) {
      /// set message is read  
      handleMessageVisibilityChanged(message, true);
    }
  },
```

```
void handleMessageVisibilityChanged(Event event, bool visible) {
    if (_isJumpingToLastReadEvent) return;
    Logs().d(
      'Chat::handleMessageVisibilityChanged() - isVisible $visible',
    );
    final isUnreadEvent = _unreadEvents.toList().firstWhereOrNull(
          (event) => event?.eventId == event?.eventId,
        );

    final inputBarHasChange = inputFocus.hasFocus;

    if (isUnreadEvent != null && inputBarHasChange) {
      _setReadMarkerEvent(isUnreadEvent);
    }

    if (isUnreadEvent != null && visible && !_isJumpingToLastReadEvent) {
      Logs().d(
        'Chat::handleMessageVisibilityChanged() - Set read Event ${isUnreadEvent.eventId}',
      );
      _setReadMarkerEvent(isUnreadEvent);
    }
  }
```

## Consequences

- Continuous listening will affect the app's performance
- The processing mechanism is not really effective because the SDK only supports setting markers for
  1 event

## Docs

https://pub.dev/packages/visibility_detector