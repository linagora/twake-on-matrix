import 'package:collection/collection.dart';
import 'package:matrix/matrix.dart';

typedef OnPinnedMessageUpdated = void Function({
  required bool isInitial,
  required bool isUnpin,
  String? eventId,
});

extension EventUpdateExtension on EventUpdate {
  String? get eventId {
    final id = content['event_id'];
    if (id != null) {
      return id;
    }
    return null;
  }

  bool get isPinnedEventsHasChanged {
    return content['type'] == EventTypes.RoomPinnedEvents;
  }

  bool get isMemberChangedEvent {
    return content['type'] == EventTypes.RoomMember;
  }

  bool _isPinnedListChanged(
    Map<String, dynamic> content,
    Map<String, dynamic> prevContent,
  ) {
    final pinnedList = content['pinned'];
    final prevPinnedList = prevContent['pinned'];

    return pinnedList != null || prevPinnedList != null;
  }

  void updatePinnedMessage({
    required OnPinnedMessageUpdated onPinnedMessageUpdated,
  }) {
    if (!isPinnedEventsHasChanged) return;
    final content = this.content['content'];
    final unsignedContent = this.content['unsigned'];
    final prevContent =
        unsignedContent != null ? unsignedContent['prev_content'] : null;
    if (content != null && prevContent != null) {
      if (!_isPinnedListChanged(content, prevContent)) return;

      final pinnedList = content['pinned'];
      final prevPinnedList = prevContent['pinned'];

      if (pinnedList.length == prevPinnedList.length) return;

      if (pinnedList.length > prevPinnedList.length) {
        _handlePinnedListIncreased(
          pinnedList,
          prevPinnedList,
          onPinnedMessageUpdated,
        );
      } else if (pinnedList.length < prevPinnedList.length) {
        _handlePinnedListDecreased(
          pinnedList,
          prevPinnedList,
          onPinnedMessageUpdated,
        );
      }
    }
  }

  void _handlePinnedListIncreased(
    List<dynamic> pinnedList,
    List<dynamic> prevPinnedList,
    OnPinnedMessageUpdated onPinnedMessageUpdated,
  ) {
    if (prevPinnedList.isEmpty) {
      return onPinnedMessageUpdated(
        isInitial: true,
        isUnpin: false,
      );
    }
    final eventId = pinnedList.firstWhereOrNull(
      (event) => !prevPinnedList.contains(event),
    );
    return onPinnedMessageUpdated(
      isInitial: false,
      isUnpin: false,
      eventId: eventId,
    );
  }

  void _handlePinnedListDecreased(
    List<dynamic> pinnedList,
    List<dynamic> prevPinnedList,
    OnPinnedMessageUpdated onPinnedMessageUpdated,
  ) {
    if (pinnedList.isEmpty) {
      return onPinnedMessageUpdated(
        isInitial: false,
        isUnpin: true,
      );
    }
    final eventId = prevPinnedList.firstWhereOrNull(
      (event) => !pinnedList.contains(event),
    );
    return onPinnedMessageUpdated(
      isInitial: false,
      isUnpin: true,
      eventId: eventId,
    );
  }
}
