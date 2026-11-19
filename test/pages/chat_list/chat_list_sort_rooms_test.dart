import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart' as provider;
import 'package:twake_chat/pages/chat_list/chat_list_sort_rooms.dart';
import 'package:twake_chat/widgets/matrix.dart';

class _Client extends Fake implements Client {
  bool logged = true;

  @override
  String get clientName => 'test';

  @override
  bool isLogged() => logged;

  @override
  bool get pinInvitedRooms => false;

  @override
  bool get pinUnreadRooms => false;
}

class _MatrixState extends Mock implements MatrixState {
  _MatrixState(this.client);

  @override
  final Client client;

  @override
  final initSettingsCompleter = Completer<void>()..complete();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_MatrixState';
}

void main() {
  late _Client client;
  late Room room;
  late ValueNotifier<bool> sortingRoomsNotifier;
  List<Room>? built;

  setUp(() {
    client = _Client();
    room = Room(id: '!room:example.com', client: client);
    sortingRoomsNotifier = ValueNotifier(true);
    built = null;
  });

  tearDown(() => sortingRoomsNotifier.dispose());

  Widget sortRooms() => ChatListSortRooms(
    rooms: [room],
    sortingRoomsNotifier: sortingRoomsNotifier,
    builder: (sortedRooms, _) {
      built = sortedRooms;
      return const SizedBox();
    },
  );

  testWidgets('drops the rooms of a client that logged out before the sort', (
    tester,
  ) async {
    await tester.pumpWidget(sortRooms());
    expect(built, [room]);

    client.logged = false;
    await tester.pumpWidget(sortRooms());

    expect(built, isEmpty);
  });

  testWidgets('drops the sorted rooms of a client that logged out', (
    tester,
  ) async {
    Widget withMatrix() => provider.Provider<MatrixState>.value(
      value: _MatrixState(client),
      child: sortRooms(),
    );

    await tester.pumpWidget(withMatrix());
    await tester.pumpAndSettle();
    expect(sortingRoomsNotifier.value, isFalse);
    expect(built, [room]);

    client.logged = false;
    await tester.pumpWidget(withMatrix());

    expect(built, isEmpty);
  });

  testWidgets('drops a room that left the list before the new sort ends', (
    tester,
  ) async {
    final other = Room(id: '!other:example.com', client: client);
    Widget withRooms(List<Room> rooms) => provider.Provider<MatrixState>.value(
      value: _MatrixState(client),
      child: ChatListSortRooms(
        rooms: rooms,
        sortingRoomsNotifier: sortingRoomsNotifier,
        builder: (sortedRooms, _) {
          built = sortedRooms;
          return const SizedBox();
        },
      ),
    );

    await tester.pumpWidget(withRooms([room, other]));
    await tester.pumpAndSettle();
    expect(built, unorderedEquals([room, other]));

    // A sync moved [other] out of this list (unpinned on another client).
    await tester.pumpWidget(withRooms([room]));

    expect(built, [room]);
  });
}
