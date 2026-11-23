import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:twake_chat/providers/matrix_client_provider.dart';
import 'package:twake_chat/widgets/twake_components/twake_navigation_icon/twake_navigation_icon.dart';
import 'package:twake_chat/widgets/unread_rooms_badge.dart';

class _FakeClient extends Fake implements Client {
  @override
  final CachedStreamController<SyncUpdate> onSync = CachedStreamController();

  @override
  final List<Room> rooms = [];
}

Future<void> _pumpBadge(WidgetTester tester, Client client) =>
    tester.pumpWidget(
      ProviderScope(
        overrides: [matrixClientProvider.overrideWithValue(client)],
        child: MaterialApp(home: UnreadRoomsBadge(filter: (_) => true)),
      ),
    );

int _shownCount(WidgetTester tester) => tester
    .widget<TwakeNavigationIcon>(find.byType(TwakeNavigationIcon))
    .notificationCount;

void main() {
  testWidgets('UnreadRoomsBadge_whenActiveClientHasAnInvite_countsIt', (
    tester,
  ) async {
    // Arrange
    final client = _FakeClient();
    client.rooms.add(
      Room(
        id: '!invite:localhost',
        client: client,
        membership: Membership.invite,
      ),
    );

    // Act
    await _pumpBadge(tester, client);

    // Assert
    expect(_shownCount(tester), 1);
  });
}
