# 16. Sticky timestamp inside chat

Date: 2024-02-07

## Status

Accepted

## Context

We need to update timestamp stick to header of Chat screen

## Decision

- Using [inview_notifier_list](https://pub.dev/packages/inview_notifier_list) combine with `ScrollNotification`
- Building a `ViewPort` is `InViewNotifierList` and item `InViewNotifierWidget` to wrap each message
- Whenever a message scroll to `ViewPort` a callback will be called to update timestamp stick to header of Chat screen
- The condition to receive the callback is `isInViewPortCondition` to the InViewNotifierList widget. 
This is the function that defines the area where the widgets overlap should be notified as currently in-view.

```dart
typedef bool IsInViewPortCondition(
  double deltaTop,
  double deltaBottom,
  double viewPortDimension,
);
```

- In this case, we will use `deltaTop` and `deltaBottom` to check if the message is in the view port or not.
Because list is **reversed**, so we change `deltaTopReversed` and `deltaBottomReversed`.

```dart
bool isInViewPortCondition(deltaTopReversed, deltaBottomReversed, viewPortDimension) {
  final stickyTimestampHeight = stickyTimestampKey.globalPaintBoundsRect?.height ?? 0;
  return deltaTopReversed < viewPortDimension - stickyTimestampHeight &&
      deltaBottomReversed > viewPortDimension - stickyTimestampHeight;
}
```

- When the message is in the viewport and new timestamp is different from the previous one, 
we will update the timestamp sticky to header of Chat screen.

## Consequences

- The timestamp will be updated when the message is in the viewport and new timestamp is different from the previous one.