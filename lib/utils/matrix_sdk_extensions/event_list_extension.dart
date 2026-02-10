import 'package:equatable/equatable.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/filtered_timeline_extension.dart';
import 'package:matrix/matrix.dart';

/// Result of syncing event lists between old and new states.
class EventListSyncResult extends Equatable {
  const EventListSyncResult({
    required this.top,
    required this.bottom,
    required this.shouldScrollToBottom,
  });

  final List<Event> top;
  final List<Event> bottom;
  final bool shouldScrollToBottom;

  @override
  List<Object?> get props => [top, bottom, shouldScrollToBottom];
}

/// Extension for managing and syncing lists of Matrix events.
/// Provides efficient operations for detecting changes, additions, and removals.
extension EventListExtension on List<Event> {
  /// Builds a map of events for O(1) lookup by eventId and transactionId.
  /// Returns a map where keys are eventId/transactionId and values are the events.
  static Map<String, Event> buildEventMap(List<Event> events) {
    final map = <String, Event>{};
    for (final event in events) {
      // Add by eventId
      map[event.eventId] = event;

      // Add by transactionId if available
      final transactionId = event.unsigned?['transaction_id'] as String?;
      if (transactionId != null) {
        map[transactionId] = event;
      }
    }
    return map;
  }

  /// Syncs two event lists (top and bottom) with new events.
  /// Handles removal of deleted events, updating of changed events,
  /// and addition of new events at the start and end.
  ///
  /// Parameters:
  /// - [oldEvents]: The previous list of events
  /// - [newEvents]: The current list of events
  /// - [currentTop]: Current events in the top list
  /// - [currentBottom]: Current events in the bottom list
  /// - [wasRequestingFuture]: Whether future events were being requested
  ///
  /// Returns [EventListSyncResult] with updated top/bottom lists and scroll flag.
  static EventListSyncResult syncEventLists({
    required List<Event> oldEvents,
    required List<Event> newEvents,
    required List<Event> currentTop,
    required List<Event> currentBottom,
    required bool wasRequestingFuture,
  }) {
    // Check if new items are completely different (use Set for O(1) lookup)
    final newEventsSet = newEvents.toSet();
    final hasCommonItems = oldEvents.any(newEventsSet.contains);

    if (!hasCommonItems) {
      // Completely different list - clear top and set bottom to new items
      return EventListSyncResult(
        top: const [],
        bottom: List.from(newEvents),
        shouldScrollToBottom: false,
      );
    }

    // Build a map for O(1) event lookups by eventId and transactionId
    final newEventsMap = buildEventMap(newEvents);

    // Remove deleted events and update changed events
    final updatedTop = _removeDeletedAndUpdate(currentTop, newEventsMap);
    final updatedBottom = _removeDeletedAndUpdate(currentBottom, newEventsMap);

    // Build a set of existing events for O(1) duplicate checking
    final existingEventsMap = buildEventMap([...updatedTop, ...updatedBottom]);

    // Find anchor points for detecting new events
    final firstOldEventInLists = _findFirstMatchingEvent(
      oldEvents,
      existingEventsMap,
    );
    final lastOldEventInLists = _findLastMatchingEvent(
      oldEvents,
      existingEventsMap,
    );

    // Find and add new items at the start
    final startDiff = _findStartDiff(newEvents, firstOldEventInLists);
    bool shouldScrollToBottom = false;

    if (startDiff > 0) {
      final newStartItems = newEvents.sublist(0, startDiff);

      // Filter out duplicates using map lookup (O(1) per item)
      final itemsToAdd = <Event>[];
      for (final newItem in newStartItems) {
        if (newItem.findEventInMap(existingEventsMap) == null) {
          itemsToAdd.add(newItem);
          // Update the map to prevent duplicates in end processing
          existingEventsMap[newItem.eventId] = newItem;
          final transactionId = newItem.unsigned?['transaction_id'] as String?;
          if (transactionId != null) {
            existingEventsMap[transactionId] = newItem;
          }
        }
      }

      updatedTop.addAll(itemsToAdd.reversed);

      // Scroll to bottom if new events arrived and conditions are met
      if (!wasRequestingFuture &&
          updatedTop.any((event) => event.isVisibleInGui)) {
        shouldScrollToBottom = true;
      }
    }

    // Find and add new items at the end
    final endDiff = _findEndDiff(newEvents, lastOldEventInLists);
    if (endDiff > 0) {
      final newEndItems = newEvents.sublist(newEvents.length - endDiff);

      // Filter out duplicates using map lookup (O(1) per item)
      final itemsToAdd = <Event>[];
      for (final newItem in newEndItems) {
        if (newItem.findEventInMap(existingEventsMap) == null) {
          itemsToAdd.add(newItem);
        }
      }

      updatedBottom.addAll(itemsToAdd);
    }

    return EventListSyncResult(
      top: updatedTop,
      bottom: updatedBottom,
      shouldScrollToBottom: shouldScrollToBottom,
    );
  }

  /// Removes deleted events and updates changed events in a list.
  static List<Event> _removeDeletedAndUpdate(
    List<Event> events,
    Map<String, Event> newEventsMap,
  ) {
    final result = <Event>[];

    for (final event in events) {
      final matchingEvent = event.findEventInMap(newEventsMap);
      if (matchingEvent != null) {
        // Keep the event, but use the updated version if different
        result.add(matchingEvent);
      }
      // If matchingEvent is null, the event was deleted, so we don't add it
    }

    return result;
  }

  /// Finds the first old event that still exists in the existing events map.
  static Event? _findFirstMatchingEvent(
    List<Event> oldEvents,
    Map<String, Event> existingEventsMap,
  ) {
    for (final oldEvent in oldEvents) {
      if (oldEvent.findEventInMap(existingEventsMap) != null) {
        return oldEvent;
      }
    }
    return null;
  }

  /// Finds the last old event that still exists in the existing events map.
  static Event? _findLastMatchingEvent(
    List<Event> oldEvents,
    Map<String, Event> existingEventsMap,
  ) {
    for (int i = oldEvents.length - 1; i >= 0; i--) {
      if (oldEvents[i].findEventInMap(existingEventsMap) != null) {
        return oldEvents[i];
      }
    }
    return null;
  }

  /// Finds how many new events are at the start of the list.
  static int _findStartDiff(
    List<Event> newEvents,
    Event? firstOldEventInLists,
  ) {
    if (firstOldEventInLists == null) return 0;

    int startDiff = 0;
    while (startDiff < newEvents.length &&
        !newEvents[startDiff].isSameEvent(firstOldEventInLists)) {
      startDiff++;
    }
    return startDiff;
  }

  /// Finds how many new events are at the end of the list.
  static int _findEndDiff(List<Event> newEvents, Event? lastOldEventInLists) {
    if (lastOldEventInLists == null) return 0;

    int endDiff = 0;
    while (endDiff < newEvents.length &&
        !newEvents[newEvents.length - 1 - endDiff].isSameEvent(
          lastOldEventInLists,
        )) {
      endDiff++;
    }
    return endDiff;
  }
}
