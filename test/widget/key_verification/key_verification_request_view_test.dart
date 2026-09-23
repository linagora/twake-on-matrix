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

/// Pumps a [KeyVerificationRequestView], leaving only what a test actually
/// varies as parameters — the shape every case shares stays in one place.
Future<void> _pumpRequestView(
  WidgetTester tester, {
  String displayName = 'Alice',
  VoidCallback onAccept = _noop,
  VoidCallback onReject = _noop,
  Size size = const Size(390, 700),
}) {
  return tester.pumpWidget(
    _wrap(
      KeyVerificationRequestView(
        displayName: displayName,
        avatarUri: null,
        onAccept: onAccept,
        onReject: onReject,
      ),
      size: size,
    ),
  );
}

void _noop() {}

void main() {
  group('KeyVerificationRequestView', () {
    testWidgets('renders title, body, and avatar', _rendersContentTest);
    testWidgets(
      'renders without exception when avatar is null',
      _nullAvatarTest,
    );
    testWidgets('tapping Accept calls onAccept once', _tapAcceptTest);
    testWidgets('tapping Reject calls onReject once', _tapRejectTest);
    testWidgets(
      'renders without overflow on phone size',
      _phoneSizeOverflowTest,
    );
    testWidgets(
      'renders without overflow on wide/web size',
      _wideSizeOverflowTest,
    );
  });
}

Future<void> _rendersContentTest(WidgetTester tester) async {
  await _pumpRequestView(tester);
  await tester.pump();

  expect(tester.takeException(), isNull);
  expect(find.text('New verification request'), findsOneWidget);
  expect(
    find.text('Accept this verification request from Alice'),
    findsOneWidget,
  );
  expect(find.text('Reject'), findsOneWidget);
  expect(find.text('Accept'), findsOneWidget);
}

Future<void> _nullAvatarTest(WidgetTester tester) async {
  await _pumpRequestView(tester, displayName: 'Bob');
  await tester.pump();

  expect(tester.takeException(), isNull);
  expect(find.text('Bob'), findsNothing);
}

Future<void> _tapAcceptTest(WidgetTester tester) async {
  var acceptTapped = 0;

  await _pumpRequestView(tester, onAccept: () => acceptTapped++);
  await tester.pump();

  await tester.tap(find.text('Accept'));
  await tester.pump();

  expect(acceptTapped, 1);
}

Future<void> _tapRejectTest(WidgetTester tester) async {
  var rejectTapped = 0;

  await _pumpRequestView(tester, onReject: () => rejectTapped++);
  await tester.pump();

  await tester.tap(find.text('Reject'));
  await tester.pump();

  expect(rejectTapped, 1);
}

Future<void> _phoneSizeOverflowTest(WidgetTester tester) async {
  await _pumpRequestView(tester, size: const Size(390, 700));
  await tester.pump();

  expect(tester.takeException(), isNull);
}

Future<void> _wideSizeOverflowTest(WidgetTester tester) async {
  await _pumpRequestView(tester, size: const Size(1280, 800));
  await tester.pump();

  expect(tester.takeException(), isNull);
}
