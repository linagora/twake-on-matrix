import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/pages/chat/chat_app_bar_title.dart';
import 'package:flutter_test/flutter_test.dart';

UnifiedContact _contact(String matrixId, String displayName) =>
    UnifiedContact(matrixId: matrixId, canonicalDisplayName: displayName);

void main() {
  group('resolveChatAppBarTitle', () {
    test('returns fallbackRoomName when directChatMatrixId is null', () {
      final name = resolveChatAppBarTitle(
        directChatMatrixId: null,
        fallbackRoomName: 'Team #42',
        localizedRoomName: 'Ignored',
        contacts: const [],
      );
      expect(name, 'Team #42');
    });

    test('returns localizedRoomName when directChatMatrixId is null and '
        'no fallbackRoomName is provided', () {
      final name = resolveChatAppBarTitle(
        directChatMatrixId: null,
        fallbackRoomName: null,
        localizedRoomName: 'Room loc',
        contacts: const [],
      );
      expect(name, 'Room loc');
    });

    test(
      'returns the displayName of the matching contact for a direct chat',
      () {
        final name = resolveChatAppBarTitle(
          directChatMatrixId: '@alice:m.org',
          fallbackRoomName: null,
          localizedRoomName: 'fallback',
          contacts: [
            _contact('@bob:m.org', 'Bob'),
            _contact('@alice:m.org', 'Alice'),
          ],
        );
        expect(name, 'Alice');
      },
    );

    test(
      'falls back to localizedRoomName when no contact matches the matrixId',
      () {
        final name = resolveChatAppBarTitle(
          directChatMatrixId: '@missing:m.org',
          fallbackRoomName: null,
          localizedRoomName: 'Fallback room',
          contacts: [_contact('@alice:m.org', 'Alice')],
        );
        expect(name, 'Fallback room');
      },
    );

    test('returns the first matching contact in iteration order when multiple '
        'contacts share the same matrixId', () {
      final name = resolveChatAppBarTitle(
        directChatMatrixId: '@shared:m.org',
        fallbackRoomName: null,
        localizedRoomName: 'Fallback',
        contacts: [
          _contact('@shared:m.org', 'From source A'),
          _contact('@shared:m.org', 'From source B'),
        ],
      );
      expect(name, 'From source A');
    });
  });
}
