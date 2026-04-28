import 'package:fluffychat/domain/matrix_events/event_visibility_resolver.dart';
import 'package:matrix/matrix.dart';

extension FilteredTimelineExtension on Event {
  bool get isVisibleInGui => EventVisibilityResolver.isVisibleInTimeline(this);

  /// True when the room creator is joining for the first time.
  /// Used by message widgets to skip the standard member-event display.
  bool isJoinedByRoomCreator() {
    return type == EventTypes.RoomMember &&
        content['membership'] == 'join' &&
        stateKey == senderId &&
        senderId == room.getState(EventTypes.RoomCreate)?.senderId;
  }
}
