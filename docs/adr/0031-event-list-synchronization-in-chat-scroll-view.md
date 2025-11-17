# 31. Event List Synchronization in Chat Scroll View

Date: 2025-11-17

## Status

Accepted

## Context

The ChatScrollView widget displays messages in a Matrix chat room using a split list approach (`_top` and `_bottom` lists) with a center anchor. When events are removed from the timeline (e.g., when a user deletes a sending message), several issues occurred:

1. App crashed with duplicate global key exceptions when removing sending events
2. Removed events still appeared on screen after deletion
3. Performance degraded with O(m×n) time complexity for event synchronization
4. Event update logic (e.g., sending → sent transitions) was mixed with removal logic
5. The `didUpdateWidget` method in ChatScrollView was approximately 160 lines, making it difficult to maintain and test

The root causes were:
- Events were being removed, updated, and re-added in a way that created duplicates
- Build method rendered events from `_bottom`/`_top` that were no longer in `widget.events`
- Linear searches through event lists resulted in quadratic time complexity
- Business logic was tightly coupled to UI code, making it untestable

## Decision

Implemented efficient event list synchronization with the following architecture:

### 1. Event Matching Logic

Created `isSameEvent` method in `LocalizedBody` extension ([lib/utils/matrix_sdk_extensions/event_extension.dart](lib/utils/matrix_sdk_extensions/event_extension.dart)) that matches events using both `eventId` and `transaction_id` to handle sending→sent transitions:

```dart
bool isSameEvent(Event other) {
  // Match by eventId
  if (eventId == other.eventId) return true;

  // Match by transaction_id
  final thisTransactionId = unsigned?['transaction_id'] as String?;
  final otherTransactionId = other.unsigned?['transaction_id'] as String?;

  if (thisTransactionId != null && otherTransactionId != null) {
    return thisTransactionId == otherTransactionId;
  }

  // Cross-match: event's transaction_id with other's eventId
  if (thisTransactionId != null && thisTransactionId == other.eventId) return true;
  if (otherTransactionId != null && otherTransactionId == eventId) return true;

  return false;
}
```

### 2. Hash Map Optimization

Created `buildEventMap` in `EventListExtension` ([lib/utils/matrix_sdk_extensions/event_list_extension.dart](lib/utils/matrix_sdk_extensions/event_list_extension.dart)) that builds event maps with dual keys (eventId and transactionId) for O(1) lookups:

```dart
static Map<String, Event> buildEventMap(List<Event> events) {
  final map = <String, Event>{};
  for (final event in events) {
    map[event.eventId] = event;
    final transactionId = event.unsigned?['transaction_id'] as String?;
    if (transactionId != null) {
      map[transactionId] = event;
    }
  }
  return map;
}
```

### 3. Reusable Event List Extension

Created `EventListExtension` with `syncEventLists` method that handles:
- Removing deleted events from display lists
- Updating changed events (e.g., sending → sent transitions)
- Adding new events at appropriate positions
- Preventing duplicate global key exceptions
- Achieving O(n) time complexity for all operations

### 4. Build-Time Safety Check

Added safety check in ChatScrollView build method to skip rendering events not found in `widget.events`:

```dart
final currentEventIndex = widget.events.indexWhere(
  (e) => _isSameEvent(e, currentEvent),
);

if (currentEventIndex == -1) {
  return const SizedBox.shrink(); // Event was deleted
}
```

### 5. Comprehensive Testing

Created [test/utils/matrix_sdk_extensions/event_list_extension_test.dart](test/utils/matrix_sdk_extensions/event_list_extension_test.dart) with 18 unit tests covering:
- Event matching by eventId and transaction_id
- Hash map building with dual keys
- Event lookup in maps
- Event synchronization scenarios (removal, addition, updates, duplicates)

## Consequences

### Positive

1. **Performance**: Reduced time complexity from O(m×n) to O(n) using hash maps
2. **Reliability**: Eliminated duplicate global key exceptions
3. **Correctness**: Deleted events are properly removed from display
4. **Maintainability**: Simplified ChatScrollView `didUpdateWidget` from ~160 lines to ~30 lines
5. **Code Quality**: Extracted reusable logic to `EventListExtension`
6. **Test Coverage**: 18 comprehensive unit tests ensuring correctness
7. **Reusability**: Event synchronization logic can be used in other widgets

### Negative

1. Memory overhead from maintaining event maps (minimal impact)
2. Additional layer of abstraction to understand

### Known Considerations

- **Matrix SDK Event Loops**: The Matrix SDK can sometimes add/remove the same event in rapid succession, creating a loop. The build-time safety check ensures such events are properly hidden when removed.
- **Performance Characteristics**:
  - Best Case: O(n) when only new events are added
  - Typical Case: O(n + m + t + b) for mixed operations
  - Worst Case: O(n + m + t + b) - no quadratic behavior

### Files Modified/Created

1. [lib/pages/chat/chat_scroll_view.dart](lib/pages/chat/chat_scroll_view.dart) - Simplified event synchronization logic
2. [lib/utils/matrix_sdk_extensions/event_extension.dart](lib/utils/matrix_sdk_extensions/event_extension.dart) - Added `isSameEvent` and `findEventInMap` methods
3. [lib/utils/matrix_sdk_extensions/event_list_extension.dart](lib/utils/matrix_sdk_extensions/event_list_extension.dart) - New extension for event list operations
4. [test/utils/matrix_sdk_extensions/event_list_extension_test.dart](test/utils/matrix_sdk_extensions/event_list_extension_test.dart) - New comprehensive test suite
