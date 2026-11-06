import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/widgets/avatar/avatar_with_kind_badge.dart';

extension PublicRoomKindBadge on PublicRoom {
  AvatarKindBadge get kindBadge => switch (this) {
    PublicRoom(kind: PublicRoomKind.feed) => AvatarKindBadge.broadcast,
    PublicRoom(access: PublicRoomAccess.open) => AvatarKindBadge.public,
    _ => AvatarKindBadge.people,
  };
}
