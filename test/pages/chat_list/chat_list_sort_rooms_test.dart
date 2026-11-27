import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderContainer, UncontrolledProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart' as provider;
import 'package:twake_chat/pages/chat_list/chat_list_sort_rooms.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
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
  late ProviderContainer container;
  late Room room;
  late ValueNotifier<bool> sortingRoomsNotifier;
  List<Room>? built;

  setUp(() {
    client = _Client();
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [activeMatrixClientProvider.overrideWithValue(client)],
    );
    room = Room(id: '!room:example.com', client: client);
    sortingRoomsNotifier = ValueNotifier(true);
    built = null;
  });

  tearDown(() => sortingRoomsNotifier.dispose());

  Widget sortRooms(List<Room> rooms, {bool hasMatrixState = false}) {
    Widget child = ChatListSortRooms(
      rooms: rooms,
      sortingRoomsNotifier: sortingRoomsNotifier,
      builder: (sortedRooms, _) {
        built = sortedRooms;
        return const SizedBox();
      },
    );
    if (hasMatrixState) {
      child = provider.Provider<MatrixState>.value(
        value: _MatrixState(client),
        child: child,
      );
    }
    return UncontrolledProviderScope(container: container, child: child);
  }

  testWidgets('drops the rooms of a client that logged out before the sort', (
    tester,
  ) async {
    await tester.pumpWidget(sortRooms([room]));
    expect(built, [room]);

    client.logged = false;
    await tester.pumpWidget(sortRooms([room]));

    expect(built, isEmpty);
  });

  testWidgets('drops the sorted rooms of a client that logged out', (
    tester,
  ) async {
    await tester.pumpWidget(sortRooms([room], hasMatrixState: true));
    await tester.pumpAndSettle();
    expect(sortingRoomsNotifier.value, isFalse);
    expect(built, [room]);

    client.logged = false;
    await tester.pumpWidget(sortRooms([room], hasMatrixState: true));

    expect(built, isEmpty);
  });

  testWidgets('drops a room that left the list before the new sort ends', (
    tester,
  ) async {
    final other = Room(id: '!other:example.com', client: client);
    await tester.pumpWidget(sortRooms([room, other], hasMatrixState: true));
    await tester.pumpAndSettle();
    expect(built, unorderedEquals([room, other]));

    // A sync took [other] out of the list (left on another client).
    await tester.pumpWidget(sortRooms([room], hasMatrixState: true));

    expect(built, [room]);
  });

  testWidgets('keeps the unsorted rooms when no account is active', (
    tester,
  ) async {
    FutureBuilder.debugRethrowError = true;
    addTearDown(() => FutureBuilder.debugRethrowError = false);
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [activeMatrixClientProvider.overrideWithValue(null)],
    );

    await tester.pumpWidget(sortRooms([room], hasMatrixState: true));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(sortingRoomsNotifier.value, isTrue);
    expect(built, [room]);
  });
}
