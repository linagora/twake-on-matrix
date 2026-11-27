import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderContainer, UncontrolledProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/personal_qr/personal_qr.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

void main() {
  testWidgets('renders nothing when no account is active', (tester) async {
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [activeMatrixClientProvider.overrideWithValue(null)],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: PersonalQr(),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Scaffold), findsNothing);
  });
}
