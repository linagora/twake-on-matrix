import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/repository/call/call_repository.provider.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_ring.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/call/incoming/incoming_call_host.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

import '../../../domain/call/fake_call_repository.dart';

final _ring = CallRing(
  eventId: r'$ring',
  room: const CallRoom('!dm:hs.test'),
  senderId: '@alice:hs.test',
  isVideo: false,
  expiresAt: DateTime(2100),
  roomName: 'Alice',
  isDirect: true,
);

void main() {
  late FakeCallRepository repository;

  Future<void> pumpHost(WidgetTester tester) async {
    repository = FakeCallRepository();
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          callRepositoryProvider.overrideWithValue(repository),
          activeMatrixClientProvider.overrideWithValue(null),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          builder: (context, child) =>
              IncomingCallHost(navigatorKey: navigatorKey, child: child!),
          home: const Scaffold(body: Text('chats')),
        ),
      ),
    );
  }

  testWidgets('mount_setsTheRingPushRulesOnce', (tester) async {
    // Act
    await pumpHost(tester);
    await tester.pump();

    // Assert
    expect(
      repository.calls.where((call) => call == 'ensureCallRingPushRules'),
      hasLength(1),
    );
  });

  testWidgets('aRing_showsOverTheAppUntilDeclined', (tester) async {
    // Arrange
    await pumpHost(tester);
    expect(find.byKey(const Key('incoming-call')), findsNothing);

    // Act
    repository.rings.add([_ring]);
    await tester.pump();

    // Assert
    expect(find.text('chats'), findsOneWidget);
    expect(find.byKey(const Key('incoming-call')), findsOneWidget);

    // Act
    await tester.tap(find.byKey(const Key('decline-call')));
    await tester.pump();

    // Assert
    expect(find.byKey(const Key('incoming-call')), findsNothing);
    expect(repository.calls, contains(r'decline $ring'));
  });

  testWidgets('aRingThatStopsElsewhere_goes', (tester) async {
    // Arrange
    await pumpHost(tester);
    repository.rings.add([_ring]);
    await tester.pump();

    // Act
    repository.rings.add([]);
    await tester.pumpAndSettle();

    // Assert
    expect(find.byKey(const Key('incoming-call')), findsNothing);
  });
}
