import 'package:twake_chat/domain/matrix_events/event_visibility_resolver.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

extension FilteredTimelineExtension on Event {
  bool get isVisibleInGui => EventVisibilityResolver.isVisibleInTimeline(
    this,
    knownThreadReplyIds:
        room.client.threadUnread?.knownThreadReplyIds(room) ?? const {},
  );

  /// True when the room creator is joining for the first time.
  /// Used by message widgets to skip the standard member-event display.
  bool isJoinedByRoomCreator() {
    return type == EventTypes.RoomMember &&
        content['membership'] == 'join' &&
        stateKey == senderId &&
        senderId == room.getState(EventTypes.RoomCreate)?.senderId;
  }
}
