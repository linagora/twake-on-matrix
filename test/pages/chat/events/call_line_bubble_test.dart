import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/domain/model/call/call_line.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/events/call_line_bubble.dart';

final _sentAt = DateTime(2026, 11, 26, 14, 32);

Future<void> _pump(
  WidgetTester tester,
  CallLine line, {
  TextScaler textScaler = TextScaler.noScaling,
}) => tester.pumpWidget(
  MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
    locale: const Locale('en'),
    localizationsDelegates: L10n.localizationsDelegates,
    supportedLocales: L10n.supportedLocales,
    home: Scaffold(
      body: CallLineBubble(line: line, sentAt: _sentAt),
    ),
  ),
);

Color? _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void _missedCallTest() {
  testWidgets('a missed call is red, with the missed arrow and its time', (
    tester,
  ) async {
    await _pump(
      tester,
      const CallLine(
        isOutgoing: false,
        isVideo: false,
        outcome: CallLineOutcome.missed,
      ),
    );

    expect(find.text('Incoming call'), findsOneWidget);
    expect(find.text('14:32'), findsOneWidget);
    expect(find.byIcon(Icons.call), findsOneWidget);
    expect(find.byIcon(Icons.call_missed), findsOneWidget);
    expect(_colorOf(tester, 'Missed'), LinagoraSysColors.material().error);
  });
}

void _answeredCallTests() {
  testWidgets('an answered video call shows its duration in green', (
    tester,
  ) async {
    await _pump(
      tester,
      const CallLine(
        isOutgoing: false,
        isVideo: true,
        outcome: CallLineOutcome.answered,
        duration: Duration(minutes: 1, seconds: 5),
      ),
    );

    expect(find.text('Incoming video call'), findsOneWidget);
    expect(find.byIcon(Icons.videocam), findsOneWidget);
    expect(find.byIcon(Icons.call_received), findsOneWidget);
    expect(_colorOf(tester, '01:05'), LinagoraSysColors.material().success);
  });

  testWidgets('a call of more than an hour shows its hours', (tester) async {
    await _pump(
      tester,
      const CallLine(
        isOutgoing: true,
        isVideo: false,
        outcome: CallLineOutcome.answered,
        duration: Duration(hours: 1, minutes: 2, seconds: 3),
      ),
    );

    expect(find.text('1:02:03'), findsOneWidget);
  });
}

void _canceledCallTest() {
  testWidgets('a call of the user nobody answered is canceled, on the right', (
    tester,
  ) async {
    await _pump(
      tester,
      const CallLine(
        isOutgoing: true,
        isVideo: false,
        outcome: CallLineOutcome.canceled,
      ),
    );

    expect(find.text('Outgoing call'), findsOneWidget);
    expect(find.byIcon(Icons.call_made), findsOneWidget);
    expect(_colorOf(tester, 'Canceled'), LinagoraSysColors.material().error);
    expect(
      tester.widget<Align>(find.byType(Align).first).alignment,
      AlignmentDirectional.centerEnd,
    );
  });
}

void _largeTextTest() {
  testWidgets('a large text wraps inside a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      const CallLine(
        isOutgoing: false,
        isVideo: true,
        outcome: CallLineOutcome.missed,
      ),
      textScaler: const TextScaler.linear(3),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(MessageBubble)).width, lessThan(320));
  });
}

void main() {
  group('missed call', _missedCallTest);
  group('answered call', _answeredCallTests);
  group('canceled call', _canceledCallTest);
  group('large text', _largeTextTest);
}
