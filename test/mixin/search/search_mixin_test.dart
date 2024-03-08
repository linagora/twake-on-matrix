import 'package:fluffychat/pages/search/search_mixin.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:flutter_test/flutter_test.dart';

class MockUpSearchMixin with SearchMixin {}

void main() {
  late MockUpSearchMixin mockSearchMixin;

  setUp(() {
    mockSearchMixin = MockUpSearchMixin();
  });

  group('SearchMixin Test', () {
    test(
      'combineDuplicateContactAndChat Test\n'
      'WHEN contacts is empty and recent chat is empty\n'
      'THEN return empty list\n',
      () {
        final List<PresentationSearch> contacts = [];
        final List<PresentationSearch> recentChat = [];

        final result = mockSearchMixin.combineDuplicateContactAndChat(
          contacts: contacts,
          recentChat: recentChat,
        );

        expect(result.isEmpty, true);
      },
    );

    test(
      'combineDuplicateContactAndChat Test\n'
      'WHEN contacts is not empty and recent chat is empty\n'
      'THEN return list with contacts only\n',
      () {
        final List<PresentationSearch> contacts = [
          const ContactPresentationSearch(
            matrixId: 'matrix_id_1',
            email: 'email1@gmail.com',
            displayName: 'display_name_1',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_2',
            email: 'email2@gmail.com',
            displayName: 'display_name_2',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_3',
            email: 'email3@gmail.com',
            displayName: 'display_name_3',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_4',
            email: 'email4@gmail.com',
            displayName: 'display_name_4',
          ),
        ];

        final List<PresentationSearch> recentChat = [];

        final List<PresentationSearch> combinedResult = [
          const ContactPresentationSearch(
            matrixId: 'matrix_id_1',
            email: 'email1@gmail.com',
            displayName: 'display_name_1',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_2',
            email: 'email2@gmail.com',
            displayName: 'display_name_2',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_3',
            email: 'email3@gmail.com',
            displayName: 'display_name_3',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_4',
            email: 'email4@gmail.com',
            displayName: 'display_name_4',
          ),
        ];

        final result = mockSearchMixin.combineDuplicateContactAndChat(
          contacts: contacts,
          recentChat: recentChat,
        );

        expect(result.isNotEmpty, true);

        expect(result.length, combinedResult.length);

        for (int i = 0; i < result.length; i++) {
          expect(result[i].id, combinedResult[i].id);
        }
      },
    );

    test(
      'combineDuplicateContactAndChat Test\n'
      'WHEN contacts is empty and recent chat is not empty\n'
      'THEN return list with recent chat only\n',
      () {
        final List<PresentationSearch> contacts = [];

        final List<PresentationSearch> recentChat = [
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_1',
            roomId: 'room_id_5',
            displayName: 'display_name_1',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_2',
            roomId: 'room_id_6',
            displayName: 'display_name_2',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_9',
            roomId: 'room_id_9',
            displayName: 'display_name_9',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_10',
            roomId: 'room_id_10',
            displayName: 'display_name_10',
          ),
        ];

        final List<PresentationSearch> combinedResult = [
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_1',
            roomId: 'room_id_5',
            displayName: 'display_name_1',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_2',
            roomId: 'room_id_6',
            displayName: 'display_name_2',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_9',
            roomId: 'room_id_9',
            displayName: 'display_name_9',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_10',
            roomId: 'room_id_10',
            displayName: 'display_name_10',
          ),
        ];

        final result = mockSearchMixin.combineDuplicateContactAndChat(
          contacts: contacts,
          recentChat: recentChat,
        );

        expect(result.isNotEmpty, true);

        expect(result.length, 4);

        for (int i = 0; i < result.length; i++) {
          expect(result[i].id, combinedResult[i].id);
        }
      },
    );

    test(
      'combineDuplicateContactAndChat Test\n'
      'WHEN contacts has 4 contacts\n'
      'AND recent chat has 4 item with only direct chat\n'
      'AND in recent chat, there is already a chat with 2 account in contacts\n'
      'THEN recent chat has removed existing accounts in contacts\n'
      'THEN return list with 6 items\n',
      () {
        final List<PresentationSearch> contacts = [
          const ContactPresentationSearch(
            matrixId: 'matrix_id_1',
            email: 'email1@gmail.com',
            displayName: 'display_name_1',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_2',
            email: 'email2@gmail.com',
            displayName: 'display_name_2',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_3',
            email: 'email3@gmail.com',
            displayName: 'display_name_3',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_4',
            email: 'email4@gmail.com',
            displayName: 'display_name_4',
          ),
        ];

        final List<PresentationSearch> recentChat = [
          const RecentChatPresentationSearch(
            directChatMatrixID: 'matrix_id_1',
            roomId: 'room_id_5',
            displayName: 'display_name_1',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'matrix_id_2',
            roomId: 'room_id_6',
            displayName: 'display_name_2',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_9',
            roomId: 'room_id_9',
            displayName: 'display_name_9',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_10',
            roomId: 'room_id_10',
            displayName: 'display_name_10',
          ),
        ];

        final List<PresentationSearch> combinedResult = [
          const ContactPresentationSearch(
            matrixId: 'matrix_id_1',
            email: 'email1@gmail.com',
            displayName: 'display_name_1',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_2',
            email: 'email2@gmail.com',
            displayName: 'display_name_2',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_3',
            email: 'email3@gmail.com',
            displayName: 'display_name_3',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_4',
            email: 'email4@gmail.com',
            displayName: 'display_name_4',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_9',
            roomId: 'room_id_9',
            displayName: 'display_name_9',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_10',
            roomId: 'room_id_10',
            displayName: 'display_name_10',
          ),
        ];

        final result = mockSearchMixin.combineDuplicateContactAndChat(
          contacts: contacts,
          recentChat: recentChat,
        );

        expect(result.isNotEmpty, true);

        expect(result.length, 6);

        for (int i = 0; i < result.length; i++) {
          expect(result[i].id, combinedResult[i].id);
        }
      },
    );

    test(
      'combineDuplicateContactAndChat Test\n'
      'WHEN contacts has 4 contacts\n'
      'AND recent chat has 4 chat with only direct chat\n'
      'AND in recent chat, there is already a chat with 1 account in contacts\n'
      'AND in recent chat, there is already a chat same name with 1 account in contacts\n'
      'THEN recent chat has removed existing accounts in contacts\n'
      'THEN return list with 7 items\n',
      () {
        final List<PresentationSearch> contacts = [
          const ContactPresentationSearch(
            matrixId: 'matrix_id_1',
            email: 'email1@gmail.com',
            displayName: 'display_name_1',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_2',
            email: 'email2@gmail.com',
            displayName: 'display_name_2',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_3',
            email: 'email3@gmail.com',
            displayName: 'display_name_3',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_4',
            email: 'email4@gmail.com',
            displayName: 'display_name_4',
          ),
        ];

        final List<PresentationSearch> recentChat = [
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_5',
            roomId: 'room_id_5',
            displayName: 'display_name_5',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_6',
            roomId: 'room_id_6',
            displayName: 'display_name_6',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_10',
            roomId: 'room_id_10',
            displayName: 'display_name_10',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'matrix_id_4',
            roomId: 'room_id_4',
            displayName: 'display_name_4',
          ),
        ];

        final List<PresentationSearch> combinedResult = [
          const ContactPresentationSearch(
            matrixId: 'matrix_id_1',
            email: 'email1@gmail.com',
            displayName: 'display_name_1',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_2',
            email: 'email2@gmail.com',
            displayName: 'display_name_2',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_3',
            email: 'email3@gmail.com',
            displayName: 'display_name_3',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_4',
            email: 'email4@gmail.com',
            displayName: 'display_name_4',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_5',
            roomId: 'room_id_5',
            displayName: 'display_name_5',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_6',
            roomId: 'room_id_6',
            displayName: 'display_name_6',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_10',
            roomId: 'room_id_10',
            displayName: 'display_name_10',
          ),
        ];

        final result = mockSearchMixin.combineDuplicateContactAndChat(
          contacts: contacts,
          recentChat: recentChat,
        );

        expect(result.isNotEmpty, true);

        expect(result.length, 7);

        for (int i = 0; i < result.length; i++) {
          expect(result[i].id, combinedResult[i].id);
        }
      },
    );

    test(
      'combineDuplicateContactAndChat Test\n'
      'WHEN contacts has 4 contacts\n'
      'AND recent chat has 4 chat with only direct chat\n'
      'AND in recent chat, there is already a chat with 1 account in contacts\n'
      'AND in recent chat, there is already a chat same matrixId with 1 account in contacts\n'
      'AND in recent chat, there is already a chat duplicate name\n'
      'THEN recent chat has removed existing accounts in contacts\n'
      'THEN return list with 7 items\n',
      () {
        final List<PresentationSearch> contacts = [
          const ContactPresentationSearch(
            matrixId: 'matrix_id_1',
            email: 'email1@gmail.com',
            displayName: 'display_name_1',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_2',
            email: 'email2@gmail.com',
            displayName: 'display_name_2',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_3',
            email: 'email3@gmail.com',
            displayName: 'display_name_3',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_4',
            email: 'email4@gmail.com',
            displayName: 'display_name_4',
          ),
        ];

        final List<PresentationSearch> recentChat = [
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_5',
            roomId: 'room_id_5',
            displayName: 'display_name_5',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_6',
            roomId: 'room_id_6',
            displayName: 'display_name_10',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_10',
            roomId: 'room_id_10',
            displayName: 'display_name_10',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'matrix_id_4',
            roomId: 'room_id_9',
            displayName: 'display_name_4',
          ),
        ];

        final List<PresentationSearch> combinedResult = [
          const ContactPresentationSearch(
            matrixId: 'matrix_id_1',
            email: 'email1@gmail.com',
            displayName: 'display_name_1',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_2',
            email: 'email2@gmail.com',
            displayName: 'display_name_2',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_3',
            email: 'email3@gmail.com',
            displayName: 'display_name_3',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_4',
            email: 'email4@gmail.com',
            displayName: 'display_name_4',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_5',
            roomId: 'room_id_5',
            displayName: 'display_name_5',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_6',
            roomId: 'room_id_6',
            displayName: 'display_name_10',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_10',
            roomId: 'room_id_10',
            displayName: 'display_name_10',
          ),
        ];

        final result = mockSearchMixin.combineDuplicateContactAndChat(
          contacts: contacts,
          recentChat: recentChat,
        );

        expect(result.isNotEmpty, true);

        expect(result.length, 7);

        for (int i = 0; i < result.length; i++) {
          expect(result[i].id, combinedResult[i].id);
        }
      },
    );

    test(
      'combineDuplicateContactAndChat Test\n'
      'WHEN contacts has 4 contacts\n'
      'AND recent chat has 4 chat with only group chat\n'
      'AND in recent chat, there is already a chat same name with 1 account in contacts\n'
      'THEN recent chat has removed existing accounts in contacts\n'
      'THEN return list with 8 items\n',
      () {
        final List<PresentationSearch> contacts = [
          const ContactPresentationSearch(
            matrixId: 'matrix_id_1',
            email: 'email1@gmail.com',
            displayName: 'display_name_1',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_2',
            email: 'email2@gmail.com',
            displayName: 'display_name_2',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_3',
            email: 'email3@gmail.com',
            displayName: 'display_name_3',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_4',
            email: 'email4@gmail.com',
            displayName: 'display_name_4',
          ),
        ];

        final List<PresentationSearch> recentChat = [
          const RecentChatPresentationSearch(
            roomId: 'room_id_5',
            displayName: 'display_name_5',
          ),
          const RecentChatPresentationSearch(
            roomId: 'room_id_6',
            displayName: 'display_name_10',
          ),
          const RecentChatPresentationSearch(
            roomId: 'room_id_10',
            displayName: 'display_name_10',
          ),
          const RecentChatPresentationSearch(
            roomId: 'room_id_9',
            displayName: 'display_name_4',
          ),
        ];

        final List<PresentationSearch> combinedResult = [
          const ContactPresentationSearch(
            matrixId: 'matrix_id_1',
            email: 'email1@gmail.com',
            displayName: 'display_name_1',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_2',
            email: 'email2@gmail.com',
            displayName: 'display_name_2',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_3',
            email: 'email3@gmail.com',
            displayName: 'display_name_3',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_4',
            email: 'email4@gmail.com',
            displayName: 'display_name_4',
          ),
          const RecentChatPresentationSearch(
            roomId: 'room_id_5',
            displayName: 'display_name_5',
          ),
          const RecentChatPresentationSearch(
            roomId: 'room_id_6',
            displayName: 'display_name_10',
          ),
          const RecentChatPresentationSearch(
            roomId: 'room_id_10',
            displayName: 'display_name_10',
          ),
          const RecentChatPresentationSearch(
            roomId: 'room_id_9',
            displayName: 'display_name_4',
          ),
        ];

        final result = mockSearchMixin.combineDuplicateContactAndChat(
          contacts: contacts,
          recentChat: recentChat,
        );

        expect(result.isNotEmpty, true);

        expect(result.length, 8);

        for (int i = 0; i < result.length; i++) {
          expect(result[i].id, combinedResult[i].id);
        }
      },
    );

    test(
      'combineDuplicateContactAndChat Test\n'
      'WHEN contacts has 4 contacts\n'
      'AND recent chat has 4 chat with direct chat and group chat\n'
      'AND in recent chat, there is already a chat same matrixId with 1 account in contacts\n'
      'THEN recent chat has removed existing accounts in contacts\n'
      'THEN return list with 8 items\n',
      () {
        final List<PresentationSearch> contacts = [
          const ContactPresentationSearch(
            matrixId: 'matrix_id_1',
            email: 'email1@gmail.com',
            displayName: 'display_name_1',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_2',
            email: 'email2@gmail.com',
            displayName: 'display_name_2',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_3',
            email: 'email3@gmail.com',
            displayName: 'display_name_3',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_4',
            email: 'email4@gmail.com',
            displayName: 'display_name_4',
          ),
        ];

        final List<PresentationSearch> recentChat = [
          const RecentChatPresentationSearch(
            roomId: 'room_id_5',
            displayName: 'display_name_5',
          ),
          const RecentChatPresentationSearch(
            roomId: 'room_id_6',
            displayName: 'display_name_10',
          ),
          const RecentChatPresentationSearch(
            roomId: 'room_id_10',
            displayName: 'display_name_10',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'matrix_id_4',
            roomId: 'room_id_9',
            displayName: 'display_name_9',
          ),
        ];

        final List<PresentationSearch> combinedResult = [
          const ContactPresentationSearch(
            matrixId: 'matrix_id_1',
            email: 'email1@gmail.com',
            displayName: 'display_name_1',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_2',
            email: 'email2@gmail.com',
            displayName: 'display_name_2',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_3',
            email: 'email3@gmail.com',
            displayName: 'display_name_3',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_4',
            email: 'email4@gmail.com',
            displayName: 'display_name_4',
          ),
          const RecentChatPresentationSearch(
            roomId: 'room_id_5',
            displayName: 'display_name_5',
          ),
          const RecentChatPresentationSearch(
            roomId: 'room_id_6',
            displayName: 'display_name_10',
          ),
          const RecentChatPresentationSearch(
            roomId: 'room_id_10',
            displayName: 'display_name_10',
          ),
        ];

        final result = mockSearchMixin.combineDuplicateContactAndChat(
          contacts: contacts,
          recentChat: recentChat,
        );

        expect(result.isNotEmpty, true);

        expect(result.length, 7);

        for (int i = 0; i < result.length; i++) {
          expect(result[i].id, combinedResult[i].id);
        }
      },
    );

    test(
      'combineDuplicateContactAndChat Test\n'
      'WHEN contacts has 4 contacts\n'
      'AND recent chat has 4 chat with direct chat and group chat\n'
      'AND in recent chat, there is already a chat same name with 1 account in contacts\n'
      'AND in recent chat, there is already a chat same name with 1 group chat\n'
      'THEN recent chat has removed existing accounts in contacts\n'
      'THEN return list with 8 items\n',
      () {
        final List<PresentationSearch> contacts = [
          const ContactPresentationSearch(
            matrixId: 'matrix_id_1',
            email: 'email1@gmail.com',
            displayName: 'display_name_1',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_2',
            email: 'email2@gmail.com',
            displayName: 'display_name_2',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_3',
            email: 'email3@gmail.com',
            displayName: 'display_name_3',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_4',
            email: 'email4@gmail.com',
            displayName: 'display_name_4',
          ),
        ];

        final List<PresentationSearch> recentChat = [
          const RecentChatPresentationSearch(
            roomId: 'room_id_5',
            displayName: 'display_name_5',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_6',
            roomId: 'room_id_6',
            displayName: 'display_name_10',
          ),
          const RecentChatPresentationSearch(
            roomId: 'room_id_10',
            displayName: 'display_name_10',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_9',
            roomId: 'room_id_9',
            displayName: 'display_name_4',
          ),
        ];

        final List<PresentationSearch> combinedResult = [
          const ContactPresentationSearch(
            matrixId: 'matrix_id_1',
            email: 'email1@gmail.com',
            displayName: 'display_name_1',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_2',
            email: 'email2@gmail.com',
            displayName: 'display_name_2',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_3',
            email: 'email3@gmail.com',
            displayName: 'display_name_3',
          ),
          const ContactPresentationSearch(
            matrixId: 'matrix_id_4',
            email: 'email4@gmail.com',
            displayName: 'display_name_4',
          ),
          const RecentChatPresentationSearch(
            roomId: 'room_id_5',
            displayName: 'display_name_5',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_6',
            roomId: 'room_id_6',
            displayName: 'display_name_10',
          ),
          const RecentChatPresentationSearch(
            roomId: 'room_id_10',
            displayName: 'display_name_10',
          ),
          const RecentChatPresentationSearch(
            directChatMatrixID: 'direct_chat_matrix_id_9',
            roomId: 'room_id_9',
            displayName: 'display_name_4',
          ),
        ];

        final result = mockSearchMixin.combineDuplicateContactAndChat(
          contacts: contacts,
          recentChat: recentChat,
        );

        expect(result.isNotEmpty, true);

        expect(result.length, 8);

        for (int i = 0; i < result.length; i++) {
          expect(result[i].id, combinedResult[i].id);
        }
      },
    );
  });
}
