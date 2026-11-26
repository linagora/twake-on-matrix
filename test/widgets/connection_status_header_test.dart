import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/widgets/connection_status_header.dart';

class _FakeClient extends Fake implements Client {
  @override
  final CachedStreamController<SyncStatusUpdate> onSyncStatus =
      CachedStreamController();

  @override
  final CachedStreamController<SyncUpdate> onSync = CachedStreamController();

  @override
  String? get prevBatch => null;
}

void main() {
  testWidgets(
    'ConnectionStatusHeader_whenClientDroppedWhileMounted_showsNothing',
    (tester) async {
      // Arrange
      Client? active = _FakeClient();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [activeMatrixClientProvider.overrideWith((ref) => active)],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            home: Scaffold(body: ConnectionStatusHeader()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Text), findsOneWidget);

      // Act
      active = null;
      ProviderScope.containerOf(
        tester.element(find.byType(ConnectionStatusHeader)),
      ).invalidate(activeMatrixClientProvider);
      await tester.pumpAndSettle();

      // Assert
      expect(tester.takeException(), isNull);
      expect(find.byType(Text), findsNothing);
    },
  );
}
