import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/widgets/connection_status_header.dart';

import '../data/account/fakes.dart';
import '../providers/fake_active_account.dart';

class _SyncClient extends FakeAccountClient {
  _SyncClient(super.clientName);

  final _onSyncStatus = CachedStreamController<SyncStatusUpdate>();
  final _onSync = CachedStreamController<SyncUpdate>();

  @override
  CachedStreamController<SyncStatusUpdate> get onSyncStatus => _onSyncStatus;

  @override
  CachedStreamController<SyncUpdate> get onSync => _onSync;

  @override
  String? get prevBatch => null;
}

void main() {
  late ProviderContainer container;
  late _SyncClient failing;
  late _SyncClient other;

  setUp(() {
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: activeAccountOverridesFollowing(),
    );
    failing = _SyncClient('failing');
    other = _SyncClient('other');
  });

  Future<void> pumpHeader(WidgetTester tester) => tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(body: ConnectionStatusHeader()),
      ),
    ),
  );

  Future<void> emit(
    WidgetTester tester,
    _SyncClient client,
    SyncStatus status,
  ) async {
    client.onSyncStatus.add(SyncStatusUpdate(status));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
  }

  testWidgets('follows the sync status of the account switched to', (
    tester,
  ) async {
    container.read(fakeActiveAccountProvider.notifier).set(failing);
    await pumpHeader(tester);
    final l10n = L10n.of(tester.element(find.byType(ConnectionStatusHeader)))!;

    await emit(tester, failing, SyncStatus.error);
    expect(find.text(l10n.oopsSomethingWentWrong), findsOneWidget);

    container.read(fakeActiveAccountProvider.notifier).set(other);
    await tester.pumpAndSettle();
    expect(find.text(l10n.oopsSomethingWentWrong), findsNothing);
    expect(find.text(l10n.waitingForResponse), findsOneWidget);

    await emit(tester, other, SyncStatus.processing);
    expect(find.text(l10n.synchronizingPleaseWait), findsOneWidget);

    await emit(tester, failing, SyncStatus.error);
    expect(find.text(l10n.oopsSomethingWentWrong), findsNothing);
    expect(find.text(l10n.synchronizingPleaseWait), findsOneWidget);
  });
}
