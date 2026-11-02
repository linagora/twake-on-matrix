import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/client_stories_extension.dart';

extension ClientRoomListExtension on Client {
  /// The rooms the room list may show: left rooms are synced too, stories
  /// have their own page.
  List<Room> get listedRooms => rooms
      .where(
        (room) =>
            (room.membership == Membership.join ||
                room.membership == Membership.invite) &&
            !room.isStoryRoom,
      )
      .toList();
}
