import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_ring.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/call/incoming/incoming_call_banner.dart';

CallRing _ring({required bool isDirect, String roomName = 'General'}) =>
    CallRing(
      eventId: r'$ring',
      room: const CallRoom('!room:hs.test'),
      senderId: '@alice:hs.test',
      isVideo: false,
      expiresAt: DateTime(2100),
      callerName: 'Alice',
      roomName: roomName,
      isDirect: isDirect,
    );

void main() {
  late List<String> taps;

  Future<void> pumpBanner(WidgetTester tester, CallRing ring) async {
    taps = [];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: IncomingCallBanner(
            ring: ring,
            onAnswer: () => taps.add('answer'),
            onDecline: () => taps.add('decline'),
          ),
        ),
      ),
    );
  }

  testWidgets('aDirectCall_namesTheChat', (tester) async {
    // Act
    await pumpBanner(tester, _ring(isDirect: true, roomName: 'Alice Martin'));

    // Assert
    expect(find.text('Alice Martin'), findsOneWidget);
    expect(find.text('is calling you'), findsOneWidget);
  });

  testWidgets('aGroupCall_namesTheCallerAndTheGroup', (tester) async {
    // Act
    await pumpBanner(tester, _ring(isDirect: false));

    // Assert
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('is calling you in General'), findsOneWidget);
  });

  testWidgets('answer_whenTapped_callsOnAnswer', (tester) async {
    // Arrange
    await pumpBanner(tester, _ring(isDirect: true));

    // Act
    await tester.tap(find.byKey(const Key('answer-call')));

    // Assert
    expect(taps, ['answer']);
  });

  testWidgets('decline_whenTapped_callsOnDecline', (tester) async {
    // Arrange
    await pumpBanner(tester, _ring(isDirect: true));

    // Act
    await tester.tap(find.byKey(const Key('decline-call')));

    // Assert
    expect(taps, ['decline']);
    expect(find.text('Decline'), findsOneWidget);
    expect(find.text('Answer'), findsOneWidget);
  });
}
