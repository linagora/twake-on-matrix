import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/generated/l10n/app_localizations_en.dart';
import 'package:twake_chat/pages/public_rooms/public_room_open_message.dart';
import 'package:twake_chat/pages/public_rooms/public_rooms_state.dart';

import '../../domain/public_rooms/fake_public_rooms_repository.dart';

void main() {
  final l10n = L10nEn();
  final open = publicRoom('!open');
  final onApproval = publicRoom('!knock', access: PublicRoomAccess.approval);

  test('message_always_matchesTheOutcome', () {
    // Arrange
    final cases = <(PublicRoomOpenResult, PublicRoom, String?)>[
      (const PublicRoomJoined('!open'), open, null),
      (const PublicRoomOpenIgnored(), open, null),
      (const PublicRoomJoinedNotInSync(), open, 'You joined the chat'),
      (
        const PublicRoomRequested(),
        onApproval,
        'Request sent: an administrator has to approve it.',
      ),
      (const PublicRoomOpenFailed(), open, 'This group could not be joined.'),
      (
        const PublicRoomOpenFailed(),
        onApproval,
        'Your request could not be sent.',
      ),
    ];

    // Act
    final messages = [
      for (final (result, room, _) in cases) result.message(l10n, room),
    ];

    // Assert
    expect(messages, [for (final (_, _, expected) in cases) expected]);
  });
}
