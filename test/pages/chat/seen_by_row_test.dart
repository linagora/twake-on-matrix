import 'package:fluffychat/pages/chat/seen_by_row.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

// getMessageStatus only checks whether the seen-by list is empty, so a bare
// fake avoids building a real User (which would require a Room).
class _FakeUser extends Fake implements User {}

void main() {
  const seenByRow = SeenByRow(
    getSeenByUsers: [],
    timelineOverlayMessage: false,
  );
  final seenByOthers = [_FakeUser()];

  group('SeenByRow.getMessageStatus', () {
    test('error status maps to error', () {
      expect(
        seenByRow.getMessageStatus(
          seenByOthers,
          eventStatus: EventStatus.error,
        ),
        MessageStatus.error,
      );
    });

    test('null status maps to sending', () {
      expect(seenByRow.getMessageStatus([]), MessageStatus.sending);
    });

    test('sending status maps to sending', () {
      expect(
        seenByRow.getMessageStatus([], eventStatus: EventStatus.sending),
        MessageStatus.sending,
      );
    });

    test('sent status maps to sent even with receipts', () {
      expect(
        seenByRow.getMessageStatus(seenByOthers, eventStatus: EventStatus.sent),
        MessageStatus.sent,
      );
    });

    test('synced without receipts maps to sent', () {
      expect(
        seenByRow.getMessageStatus([], eventStatus: EventStatus.synced),
        MessageStatus.sent,
      );
    });

    test('synced with receipts maps to hasBeenSeen', () {
      expect(
        seenByRow.getMessageStatus(
          seenByOthers,
          eventStatus: EventStatus.synced,
        ),
        MessageStatus.hasBeenSeen,
      );
    });
  });
}
