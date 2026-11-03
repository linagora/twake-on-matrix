import 'package:freezed_annotation/freezed_annotation.dart';

part 'public_room.freezed.dart';

enum PublicRoomAccess { open, approval }

enum PublicRoomKind { group, feed, space, other }

@freezed
abstract class PublicRoom with _$PublicRoom {
  const factory PublicRoom({
    required String roomId,
    required String name,
    required int memberCount,
    required PublicRoomAccess access,
    required PublicRoomKind kind,
    String? topic,
    Uri? avatarUri,
  }) = _PublicRoom;
}
