import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/key_verification/key_verification_request_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {Size size = const Size(390, 700)}) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: LocalizationService.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('KeyVerificationRequestView', () {
    testWidgets('renders title, body, and avatar', (tester) async {
      await tester.pumpWidget(
        _wrap(
          KeyVerificationRequestView(
            displayName: 'Alice',
            avatarUri: null,
            onAccept: () {},
            onReject: () {},
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('New verification request'), findsOneWidget);
      expect(
        find.text('Accept this verification request from Alice'),
        findsOneWidget,
      );
      expect(find.text('Reject'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
    });

    testWidgets('renders without exception when avatar is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          KeyVerificationRequestView(
            displayName: 'Bob',
            avatarUri: null,
            onAccept: () {},
            onReject: () {},
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Bob'), findsNothing);
    });

    testWidgets('tapping Accept calls onAccept once', (tester) async {
      var acceptTapped = 0;

      await tester.pumpWidget(
        _wrap(
          KeyVerificationRequestView(
            displayName: 'Alice',
            avatarUri: null,
            onAccept: () => acceptTapped++,
            onReject: () {},
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Accept'));
      await tester.pump();

      expect(acceptTapped, 1);
    });

    testWidgets('tapping Reject calls onReject once', (tester) async {
      var rejectTapped = 0;

      await tester.pumpWidget(
        _wrap(
          KeyVerificationRequestView(
            displayName: 'Alice',
            avatarUri: null,
            onAccept: () {},
            onReject: () => rejectTapped++,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Reject'));
      await tester.pump();

      expect(rejectTapped, 1);
    });

    testWidgets('renders without overflow on phone size', (tester) async {
      await tester.pumpWidget(
        _wrap(
          KeyVerificationRequestView(
            displayName: 'Alice',
            avatarUri: null,
            onAccept: () {},
            onReject: () {},
          ),
          size: const Size(390, 700),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on wide/web size', (tester) async {
      await tester.pumpWidget(
        _wrap(
          KeyVerificationRequestView(
            displayName: 'Alice',
            avatarUri: null,
            onAccept: () {},
            onReject: () {},
          ),
          size: const Size(1280, 800),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
