import 'package:matrix/matrix.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

class RoomNoLongerJoinableException implements Exception {
  const RoomNoLongerJoinableException(this.message);

  final String message;

  @override
  String toString() => message;
}

// Synapse gives no specific errcode, only M_UNKNOWN with one of these texts.
const _noServerLeftInRoomMessages = {
  "Can't join remote room because no servers that are in the room have been "
      'provided.',
  'No known servers',
};

extension JoinInvitationErrorExtension on MatrixException {
  Exception toJoinInvitationError(L10n l10n) =>
      error == MatrixError.M_UNKNOWN &&
          _noServerLeftInRoomMessages.contains(errorMessage)
      ? RoomNoLongerJoinableException(l10n.cannotJoinRoomEveryoneLeft)
      : this;
}
