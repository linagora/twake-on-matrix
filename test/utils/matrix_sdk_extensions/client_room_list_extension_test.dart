import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/presentation/extensions/client_extension.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/client_room_list_extension.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/client_stories_extension.dart';

import 'client_room_list_extension_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Client>(), MockSpec<Room>()])
MockRoom _room(
  String id,
  Membership membership, {
  bool isSpace = false,
  bool isStory = false,
}) {
  final room = MockRoom();
  when(room.id).thenReturn(id);
  when(room.membership).thenReturn(membership);
  when(room.isSpace).thenReturn(isSpace);
  when(room.isFavourite).thenReturn(false);
  when(room.getState(EventTypes.RoomCreate)).thenReturn(
    isStory
        ? StrippedStateEvent(
            type: EventTypes.RoomCreate,
            content: {'type': ClientStoriesExtension.storiesRoomType},
            senderId: '@a:b',
          )
        : null,
  );
  return room;
}

void main() {
  late MockClient client;

  setUp(() {
    client = MockClient();
    final rooms = [
      _room('!joined', Membership.join),
      _room('!invited', Membership.invite),
      _room('!space', Membership.join, isSpace: true),
      _room('!story', Membership.join, isStory: true),
      _room('!left', Membership.leave),
      _room('!banned', Membership.ban),
      _room('!knocked', Membership.knock),
    ];
    when(client.rooms).thenReturn(rooms);
  });

  List<String> ids(List<Room> rooms) => rooms.map((room) => room.id).toList();

  test('listedRooms_always_keepsJoinedAndInvitedWithoutStories', () {
    expect(ids(client.listedRooms), ['!joined', '!invited', '!space']);
  });

  test('acceptedRooms_always_keepsOnlyJoinedConversations', () {
    expect(client.acceptedRooms.map((room) => room.id), ['!joined']);
  });
}
