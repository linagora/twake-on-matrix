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

/// Bundles what a single test case varies, so [_pumpRequestView] stays a
/// two-argument function regardless of how many fields a case sets.
class _RequestViewCase {
  final String displayName;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final Size size;

  const _RequestViewCase({
    this.displayName = 'Alice',
    this.onAccept = _noop,
    this.onReject = _noop,
    this.size = const Size(390, 700),
  });
}

void _noop() {}

/// Pumps a [KeyVerificationRequestView] for [testCase] — the shape every
/// case shares stays in one place; only [testCase] varies per test.
Future<void> _pumpRequestView(WidgetTester tester, _RequestViewCase testCase) {
  return tester.pumpWidget(
    _wrap(
      KeyVerificationRequestView(
        displayName: testCase.displayName,
        avatarUri: null,
        onAccept: testCase.onAccept,
        onReject: testCase.onReject,
      ),
      size: testCase.size,
    ),
  );
}

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
  await _pumpRequestView(tester, const _RequestViewCase());
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
  await _pumpRequestView(tester, const _RequestViewCase(displayName: 'Bob'));
  await tester.pump();

  expect(tester.takeException(), isNull);
  expect(find.text('Bob'), findsNothing);
}

Future<void> _tapAcceptTest(WidgetTester tester) async {
  var acceptTapped = 0;

  await _pumpRequestView(
    tester,
    _RequestViewCase(onAccept: () => acceptTapped++),
  );
  await tester.pump();

  await tester.tap(find.text('Accept'));
  await tester.pump();

  expect(acceptTapped, 1);
}

Future<void> _tapRejectTest(WidgetTester tester) async {
  var rejectTapped = 0;

  await _pumpRequestView(
    tester,
    _RequestViewCase(onReject: () => rejectTapped++),
  );
  await tester.pump();

  await tester.tap(find.text('Reject'));
  await tester.pump();

  expect(rejectTapped, 1);
}

Future<void> _phoneSizeOverflowTest(WidgetTester tester) async {
  await _pumpRequestView(tester, const _RequestViewCase(size: Size(390, 700)));
  await tester.pump();

  expect(tester.takeException(), isNull);
}

Future<void> _wideSizeOverflowTest(WidgetTester tester) async {
  await _pumpRequestView(tester, const _RequestViewCase(size: Size(1280, 800)));
  await tester.pump();

  expect(tester.takeException(), isNull);
}
