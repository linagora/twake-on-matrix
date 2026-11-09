import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/public_rooms/public_rooms_state.dart';

extension PublicRoomOpenMessage on PublicRoomOpenResult {
  /// What to tell the user after a tap on [room], if anything.
  String? message(L10n l10n, PublicRoom room) => switch (this) {
    PublicRoomJoinedNotInSync() => l10n.youJoinedTheChat,
    PublicRoomRequested() => l10n.joinRequestSentAdminMustApprove,
    PublicRoomOpenFailed() =>
      room.access == PublicRoomAccess.approval
          ? l10n.publicGroupRequestFailed
          : l10n.publicGroupJoinFailed,
    PublicRoomJoined() || PublicRoomOpenIgnored() => null,
  };
}
