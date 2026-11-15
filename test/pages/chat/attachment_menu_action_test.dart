import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/chat/chat_actions.dart';

void main() {
  group('AttachmentMenuAction.available', () {
    test('offers Drive when it is enabled', () {
      expect(
        AttachmentMenuAction.available(driveEnabled: true),
        AttachmentMenuAction.values,
      );
    });

    test('hides Drive and keeps the other entries when it is off', () {
      final actions = AttachmentMenuAction.available(driveEnabled: false);

      expect(actions, isNot(contains(AttachmentMenuAction.drive)));
      expect(actions, [
        AttachmentMenuAction.gallery,
        AttachmentMenuAction.document,
        AttachmentMenuAction.camera,
      ]);
    });
  });
}
