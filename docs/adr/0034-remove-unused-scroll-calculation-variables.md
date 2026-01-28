# 34. Fix Chat Scrolling Issues

Date: 2026-01-27

## Status

Accepted

## Context

While implementing the "Jump to search result" feature (TW-2854), we found two problems in the chat scrolling code:

### Problem 1: Wasted Calculations

The code was calculating three values that were never used:

- `nearestPosition` - calculated but completely ignored
- `viewportHeight` - calculated here, then recalculated later when actually needed
- `currentOffset` - calculated here, then recalculated later when actually needed

This made the code confusing and slower than necessary.

### Problem 2: Auto-Loading During Jumps

When the app automatically scrolls to a message (e.g., "jump to search result"), it was also loading more message history in the background. This caused:

- The list of messages changing while scrolling
- The target message moving to a different position
- Unnecessary network requests
- The scroll sometimes missing the target message

The code couldn't tell the difference between:

- **User scrolling**: Should load more messages automatically
- **App scrolling**: Should NOT load messages until the scroll is complete

## Solution

### 1. Remove Unused Code

Deleted the three unused variable calculations. The values are now only calculated when actually needed.

**Before:**

```dart
final nearestPosition = nearestBox.localToGlobal(...);
final viewportHeight = scrollBox.size.height;
final currentOffset = scrollController.offset;
// These were never used here!
```

**After:**

```dart
// Variables calculated only when needed later in the code
```

### 2. Add a "Don't Auto-Load" Flag

Added a flag `_isProgrammaticScrolling` that tells the auto-loading code to pause during app-initiated scrolls:

```dart
bool _isProgrammaticScrolling = false;
```

When jumping to a message:

1. Set `_isProgrammaticScrolling = true`
2. Scroll to the message
3. Set `_isProgrammaticScrolling = false`

The auto-loading code checks this flag and skips loading if it's `true`:

```dart
if (_isProgrammaticScrolling) {
  return; // Don't auto-load during jumps
}
```

We use a `try-finally` block to ensure the flag is always reset, even if something goes wrong.

### 3. Clean Up Old Code

Removed the unused `_fastScrollThreshold` constant.

## Consequences

### Benefits

- **Better Performance**: Fewer unnecessary calculations and network requests
- **Reliable Jumps**: "Jump to message" features now work consistently
- **Still Auto-Loads**: User scrolling still loads more messages automatically
