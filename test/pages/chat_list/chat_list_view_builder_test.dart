import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart' as provider;
import 'package:twake_chat/domain/spaces/room_list_entry.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_list/chat_list_view_builder.dart';
import 'package:twake_chat/providers/room_list/folded_spaces_controller.dart';
import 'package:twake_chat/providers/room_list/room_list_providers.dart';
import 'package:twake_chat/widgets/matrix.dart';

import 'chat_list_header_test_harness.dart';

class _Client extends Fake implements Client {
  bool logged = true;

  @override
  String get clientName => 'test';

  @override
  bool isLogged() => logged;
}

class _NoFold extends FoldedSpacesController {
  @override
  Future<Set<String>> build() async => <String>{};
}

void main() {
  final emptyText = lookupL10n(const Locale('en')).roomListEmptyView;

  Future<void> pumpList(WidgetTester tester, Client client, List<Room> rooms) {
    final matrix = FakeMatrixState(client);
    final controller = FakeChatListController(matrix, client);
    addTearDown(controller.scrollController.dispose);
    return tester.pumpWidget(
      provider.Provider<MatrixState>.value(
        value: matrix,
        child: UncontrolledProviderScope(
          container: ProviderContainer.test(
            overrides: [
              roomListContentProvider.overrideWith(
                (ref, _) => RoomListContent(
                  visible: [
                    for (final room in rooms)
                      RoomListEntry(id: room.id, name: room.id),
                  ],
                  foldedSpaceIds: const {},
                  joinableBySpace: const {},
                ),
              ),
              foldedSpacesControllerProvider.overrideWith(_NoFold.new),
            ],
          ),
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            home: CustomScrollView(
              slivers: [
                ChatListViewBuilder(controller: controller, rooms: rooms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the empty text when the account has no room', (
    tester,
  ) async {
    await pumpList(tester, _Client(), const []);
    await tester.pumpAndSettle();

    expect(find.text(emptyText), findsOneWidget);
  });

  testWidgets('shows nothing when every room belongs to a logged-out client', (
    tester,
  ) async {
    final client = _Client()..logged = false;
    final room = Room(id: '!room:example.com', client: client);

    await pumpList(tester, client, [room]);
    await tester.pumpAndSettle();

    expect(find.text(emptyText), findsNothing);
  });
}
