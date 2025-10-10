import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:matrix/matrix.dart';

/// Represents a group of consecutive events that should be displayed together
class GroupedEvents {
  /// The main event (first event in the group)
  final Event mainEvent;

  /// List of additional events in the group (excluding the main event)
  final List<Event> additionalEvents;

  /// Whether this is a grouped event (has additional events)
  bool get isGrouped => additionalEvents.isNotEmpty;

  /// All events in the group (main event + additional events)
  List<Event> get allEvents => [mainEvent, ...additionalEvents];

  GroupedEvents({
    required this.mainEvent,
    this.additionalEvents = const [],
  });

  /// Creates a single event group (not grouped)
  factory GroupedEvents.single(Event event) {
    return GroupedEvents(mainEvent: event);
  }

  /// Creates a grouped event with multiple events
  factory GroupedEvents.multiple(List<Event> events) {
    if (events.isEmpty) {
      throw ArgumentError('Events list cannot be empty');
    }
    return GroupedEvents(
      mainEvent: events.first,
      additionalEvents: events.sublist(1),
    );
  }
}

/// Helper class to group consecutive image events
mixin EventGrouperMixin {
  /// Groups consecutive image events with matching image_bubble_id
  /// Only groups images from the same sender that have the same non-null groupId
  List<GroupedEvents> groupEvents(List<Event> events) {
    final List<GroupedEvents> groupedEvents = [];
    int i = 0;

    while (i < events.length) {
      final event = events[i];

      // Check if this is an image event without caption
      if (_isGroupableImage(event)) {
        final List<Event> imageGroup = [event];
        final sender = event.senderId;
        final groupId = event.imageBubbleId();
        int j = i + 1;

        // Collect consecutive images with matching groupId
        while (j < events.length) {
          final nextEvent = events[j];
          final nextGroupId = nextEvent.imageBubbleId();

          // Only group if both events have the same non-null groupId
          final shouldGroup = _isGroupableImage(nextEvent) &&
              nextEvent.senderId == sender &&
              groupId != null &&
              groupId == nextGroupId;

          if (shouldGroup) {
            imageGroup.add(nextEvent);
            j++;
          } else {
            break;
          }
        }

        // Create grouped event
        if (imageGroup.length > 1) {
          groupedEvents.add(GroupedEvents.multiple(imageGroup));
          i = j;
        } else {
          groupedEvents.add(GroupedEvents.single(event));
          i++;
        }
      } else {
        groupedEvents.add(GroupedEvents.single(event));
        i++;
      }
    }

    return groupedEvents;
  }

  /// Checks if an event is a groupable image (image without caption)
  bool _isGroupableImage(Event event) {
    if (event.messageType != MessageTypes.Image) {
      return false;
    }

    // Don't group images with captions
    final body = event.content.tryGet<String>('body') ?? '';
    final filename = event.content
        .tryGetMap<String, dynamic>('info')
        ?.tryGet<String>('filename');

    // If body is different from filename, it has a caption
    if (filename != null && body != filename) {
      return false;
    }

    if (event.imageBubbleId() == null) {
      return false;
    }

    return true;
  }
}
