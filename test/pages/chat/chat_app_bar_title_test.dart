import 'package:dartz/dartz.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/pages/chat/chat_app_bar_title.dart';
import 'package:flutter_test/flutter_test.dart';

Contact _contactWithMatrixId(String id, String matrixId, String displayName) {
  return Contact(
    id: id,
    displayName: displayName,
    emails: {Email(address: '$id@example.com', matrixId: matrixId)},
  );
}

void main() {
  group('resolveChatAppBarTitle', () {
    test('returns fallbackRoomName when directChatMatrixId is null', () {
      final name = resolveChatAppBarTitle(
        directChatMatrixId: null,
        fallbackRoomName: 'Team #42',
        localizedRoomName: 'Ignored',
        getContactsState: const Right(GetContactsSuccess(contacts: [])),
      );
      expect(name, 'Team #42');
    });

    test('returns localizedRoomName when directChatMatrixId is null and '
        'no fallbackRoomName is provided', () {
      final name = resolveChatAppBarTitle(
        directChatMatrixId: null,
        fallbackRoomName: null,
        localizedRoomName: 'Room loc',
        getContactsState: const Right(GetContactsSuccess(contacts: [])),
      );
      expect(name, 'Room loc');
    });

    test(
      'returns the displayName of the matching contact for a direct chat',
      () {
        final match = _contactWithMatrixId('1', '@alice:m.org', 'Alice');
        final other = _contactWithMatrixId('2', '@bob:m.org', 'Bob');
        final name = resolveChatAppBarTitle(
          directChatMatrixId: '@alice:m.org',
          fallbackRoomName: null,
          localizedRoomName: 'fallback',
          getContactsState: Right(GetContactsSuccess(contacts: [other, match])),
        );
        expect(name, 'Alice');
      },
    );

    test(
      'falls back to localizedRoomName when no contact matches the matrixId',
      () {
        final contact = _contactWithMatrixId('1', '@alice:m.org', 'Alice');
        final name = resolveChatAppBarTitle(
          directChatMatrixId: '@missing:m.org',
          fallbackRoomName: null,
          localizedRoomName: 'Fallback room',
          getContactsState: Right(GetContactsSuccess(contacts: [contact])),
        );
        expect(name, 'Fallback room');
      },
    );

    test('falls back to localizedRoomName when state is a Failure', () {
      final name = resolveChatAppBarTitle(
        directChatMatrixId: '@alice:m.org',
        fallbackRoomName: null,
        localizedRoomName: 'Fallback on failure',
        getContactsState: const Left(
          GetContactsFailure(keyword: '', exception: 'boom'),
        ),
      );
      expect(name, 'Fallback on failure');
    });

    test('returns the first matching contact in iteration order when multiple '
        'contacts share the same matrixId', () {
      final first = _contactWithMatrixId('1', '@shared:m.org', 'From source A');
      final second = _contactWithMatrixId(
        '2',
        '@shared:m.org',
        'From source B',
      );
      final name = resolveChatAppBarTitle(
        directChatMatrixId: '@shared:m.org',
        fallbackRoomName: null,
        localizedRoomName: 'Fallback',
        getContactsState: Right(GetContactsSuccess(contacts: [first, second])),
      );
      expect(name, 'From source A');
    });
  });
}
