import 'package:matrix/matrix.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

class RoomNoLongerJoinableException implements Exception {
  const RoomNoLongerJoinableException(this.message);

  final String message;

  @override
  String toString() => message;
}

extension JoinInvitationErrorExtension on MatrixException {
  // Room.join already rejects the invite when it gets this errcode.
  Exception toJoinInvitationError(L10n l10n) => error == MatrixError.M_UNKNOWN
      ? RoomNoLongerJoinableException(l10n.cannotJoinRoomEveryoneLeft)
      : this;
}
