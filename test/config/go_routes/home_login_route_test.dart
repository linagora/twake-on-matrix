import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/pages/login/login_client_owner.dart';
import 'package:twake_chat/widgets/matrix.dart';

class _LoggedOutMatrixState extends Fake implements MatrixState {
  @override
  bool isLoggedInClient() => false;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_LoggedOutMatrixState';
}

void main() {
  testWidgets(
    'redirect_whenTheLoginRouteCarriesAClientOwner_doesNotThrowOnTheParent',
    (tester) async {
      // Arrange: go_router runs the redirect of /home for /home/login too,
      // with the extra of the login route.
      final router = GoRouter(
        routes: [$homeRoute as GoRoute],
        initialLocation: '/home',
      );
      addTearDown(router.dispose);
      late BuildContext context;
      await tester.pumpWidget(
        Provider<MatrixState>.value(
          value: _LoggedOutMatrixState(),
          child: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      final state = GoRouterState(
        router.configuration,
        uri: Uri.parse('/home/login'),
        matchedLocation: '/home/login',
        fullPath: '/home/login',
        pathParameters: const {},
        pageKey: const ValueKey('login'),
        extra: LoginClientOwner.thisPage,
      );

      // Act
      final redirect = ($homeRoute as GoRoute).redirect!(context, state);

      // Assert
      expect(await redirect, isNull);
    },
  );
}
