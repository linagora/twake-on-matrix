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

    for (final size in const [Size(390, 700), Size(1280, 800)]) {
      testWidgets(
        'renders without overflow at $size',
        (tester) => _overflowTest(tester, size),
      );
    }

    testWidgets('tapping Accept calls onAccept once', (tester) async {
      var tapped = 0;
      await _pumpRequestView(
        tester,
        _RequestViewCase(onAccept: () => tapped++),
      );
      await _tapAndExpectOnce(tester, 'Accept', () => tapped);
    });

    testWidgets('tapping Reject calls onReject once', (tester) async {
      var tapped = 0;
      await _pumpRequestView(
        tester,
        _RequestViewCase(onReject: () => tapped++),
      );
      await _tapAndExpectOnce(tester, 'Reject', () => tapped);
    });
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

Future<void> _overflowTest(WidgetTester tester, Size size) async {
  await _pumpRequestView(tester, _RequestViewCase(size: size));
  await tester.pump();

  expect(tester.takeException(), isNull);
}

/// Taps the button labelled [label] and asserts the counter it feeds reads
/// exactly 1 afterwards — shared by the Accept and Reject tap tests.
Future<void> _tapAndExpectOnce(
  WidgetTester tester,
  String label,
  int Function() readTapCount,
) async {
  await tester.pump();
  await tester.tap(find.text(label));
  await tester.pump();

  expect(readTapCount(), 1);
}
