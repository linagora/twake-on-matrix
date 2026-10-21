import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/client_stories_extension.dart';

class _FakeRoom extends Fake implements Room {
  _FakeRoom({
    required this.membership,
    this.isSpace = false,
    this.isDirectChat = false,
    this.isStory = false,
  });

  @override
  final Membership membership;

  @override
  final bool isSpace;

  @override
  final bool isDirectChat;

  final bool isStory;

  @override
  StrippedStateEvent? getState(String typeKey, [String stateKey = '']) {
    if (!isStory || typeKey != EventTypes.RoomCreate) return null;
    return StrippedStateEvent(
      type: EventTypes.RoomCreate,
      content: {'type': ClientStoriesExtension.storiesRoomType},
      senderId: '@story:example.org',
    );
  }
}

void main() {
  group('ActiveFilter.getRoomFilterByActiveFilter', () {
    final leftStates = [Membership.leave, Membership.ban, Membership.knock];
    final listedStates = [Membership.join, Membership.invite];

    for (final filter in ActiveFilter.values) {
      final matchingRoom = switch (filter) {
        ActiveFilter.spaces => (Membership m) => _FakeRoom(
          membership: m,
          isSpace: true,
        ),
        ActiveFilter.messages => (Membership m) => _FakeRoom(
          membership: m,
          isDirectChat: true,
        ),
        _ => (Membership m) => _FakeRoom(membership: m),
      };

      test('$filter lists joined and invited rooms it matches', () {
        final matches = filter.getRoomFilterByActiveFilter();
        for (final membership in listedStates) {
          // acceptedChats deliberately excludes invitations.
          final expected =
              !(filter == ActiveFilter.acceptedChats &&
                  membership == Membership.invite);
          expect(
            matches(matchingRoom(membership)),
            expected,
            reason: '$membership',
          );
        }
      });

      test('$filter hides rooms that are left, banned or only knocked', () {
        final matches = filter.getRoomFilterByActiveFilter();
        for (final membership in leftStates) {
          expect(
            matches(matchingRoom(membership)),
            isFalse,
            reason: '$membership',
          );
        }
      });
    }

    test('allChats excludes spaces and story rooms', () {
      final matches = ActiveFilter.allChats.getRoomFilterByActiveFilter();

      expect(
        matches(_FakeRoom(membership: Membership.join, isSpace: true)),
        isFalse,
      );
      expect(
        matches(_FakeRoom(membership: Membership.join, isStory: true)),
        isFalse,
      );
    });
  });
}
