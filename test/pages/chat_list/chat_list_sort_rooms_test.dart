import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/pages/chat_list/chat_list_sort_rooms.dart';

class _Client extends Fake implements Client {
  bool logged = true;

  @override
  String get clientName => 'test';

  @override
  bool isLogged() => logged;
}

void main() {
  testWidgets('drops the rooms of a client that logged out', (tester) async {
    final client = _Client();
    final room = Room(id: '!room:example.com', client: client);
    final sortingRoomsNotifier = ValueNotifier(true);
    addTearDown(sortingRoomsNotifier.dispose);
    List<Room>? built;

    Widget sortRooms() => ChatListSortRooms(
      rooms: [room],
      sortingRoomsNotifier: sortingRoomsNotifier,
      builder: (sortedRooms, _) {
        built = sortedRooms;
        return const SizedBox();
      },
    );

    await tester.pumpWidget(sortRooms());
    expect(built, [room]);

    client.logged = false;
    await tester.pumpWidget(sortRooms());

    expect(built, isEmpty);
  });
}
