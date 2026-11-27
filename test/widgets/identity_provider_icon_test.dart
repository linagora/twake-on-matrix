import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/pages/connect/connect_page.dart';
import 'package:twake_chat/providers/login_sessions_provider.dart';
import 'package:twake_chat/widgets/identity_provider_icon.dart';

import '../providers/fake_login_sessions.dart';

void main() {
  group('IdentityProviderIcon', () {
    late int loginClientCalls;

    Future<void> pumpIcon(
      WidgetTester tester,
      Future<Client> Function() loginClient,
    ) async {
      loginClientCalls = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginSessionsProvider.overrideWithValue(
              FakeLoginSessions(
                loginClient: () {
                  loginClientCalls++;
                  return loginClient();
                },
              ),
            ),
          ],
          child: MaterialApp(
            home: IdentityProviderIcon(
              identityProvider: IdentityProvider(id: 'oidc'),
              size: 24,
            ),
          ),
        ),
      );
    }

    testWidgets('keeps the place while the login client loads', (tester) async {
      // Arrange
      final pending = Completer<Client>();

      // Act
      await pumpIcon(tester, () => pending.future);

      // Assert
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
      expect(loginClientCalls, 1);
    });

    testWidgets('shows an error icon when the login client fails', (
      tester,
    ) async {
      // Arrange
      Future<Client> failing() async => throw StateError('no client');

      // Act
      await pumpIcon(tester, failing);
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
