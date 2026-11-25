import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/widgets/twake_components/twake_navigation_icon/twake_navigation_icon.dart';
import 'package:twake_chat/widgets/unread_rooms_badge.dart';

class _FakeClient extends Fake implements Client {
  @override
  final CachedStreamController<SyncUpdate> onSync = CachedStreamController();

  @override
  final List<Room> rooms = [];
}

Future<void> _pumpBadge(WidgetTester tester, Client? Function() active) =>
    tester.pumpWidget(
      ProviderScope(
        overrides: [activeMatrixClientProvider.overrideWith((ref) => active())],
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
    await _pumpBadge(tester, () => client);

    // Assert
    expect(_shownCount(tester), 1);
  });

  testWidgets('UnreadRoomsBadge_whenClientDroppedWhileMounted_showsNothing', (
    tester,
  ) async {
    // Arrange
    Client? active = _FakeClient();
    await _pumpBadge(tester, () => active);
    expect(find.byType(TwakeNavigationIcon), findsOneWidget);

    // Act
    active = null;
    ProviderScope.containerOf(
      tester.element(find.byType(UnreadRoomsBadge)),
    ).invalidate(activeMatrixClientProvider);
    await tester.pump();

    // Assert
    expect(tester.takeException(), isNull);
    expect(find.byType(TwakeNavigationIcon), findsNothing);
  });
}
