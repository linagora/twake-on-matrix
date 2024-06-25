import 'package:fluffychat/utils/room_status_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:mockito/annotations.dart';

import 'get_localize_status_test.mocks.dart';

@GenerateMocks(
  [
    Logs,
    Client,
  ],
)
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  group("getLocalizedStatus function test", () {
    const textWidgetKey = ValueKey('textWidget');

    testWidgets(
        'GIVEN the presenceType be online\n'
        'THEN should display the status as active now\n',
        (WidgetTester tester) async {
      // Given
      final presence = CachedPresence(
        PresenceType.online,
        0,
        "",
        true,
        "testuserid",
      );

      // WHEN
      await prepareTextWidget(presence, textWidgetKey, tester);

      //EXPECT
      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals('Active now'));
    });

    testWidgets(
        'GIVEN the presence time to be one minute from present with currently active be false\n'
        'THEN should display the status as active now\n',
        (WidgetTester tester) async {
      // Given
      final lessThanOneMinuteAgo = const Duration(seconds: 30).inMilliseconds;
      final presence = CachedPresence(
        PresenceType.offline,
        lessThanOneMinuteAgo,
        "",
        false,
        "testuserid",
      );

      // WHEN
      await prepareTextWidget(presence, textWidgetKey, tester);

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals('Active now'));
    });

    testWidgets(
        'GIVEN the presence time to be 10 minute from present with currently active be false\n'
        'THEN should display the status as online 10 minutes ago\n',
        (WidgetTester tester) async {
      // Given
      final lessThan10MinutesAgo = (const Duration(minutes: 10)).inMilliseconds;
      final presence = CachedPresence(
        PresenceType.offline,
        lessThan10MinutesAgo,
        "",
        false,
        "testuserid",
      );

      // WHEN
      await prepareTextWidget(presence, textWidgetKey, tester);

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals('online 10m ago'));
    });

    testWidgets(
        'GIVEN the presence time to be 10 minute from present with currently active be false\n'
        'THEN should display the status as online 10 minutes ago\n',
        (WidgetTester tester) async {
      // Given
      final lessThan10MinutesAgo = (const Duration(minutes: 10)).inMilliseconds;
      final presence = CachedPresence(
        PresenceType.offline,
        lessThan10MinutesAgo,
        "",
        false,
        "testuserid",
      );

      // WHEN
      await prepareTextWidget(presence, textWidgetKey, tester);

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals('online 10m ago'));
    });

    testWidgets(
        'GIVEN the presence time to be 10 minute from present with currently active be false\n'
        'THEN should display the status as online 10 minutes ago\n',
        (WidgetTester tester) async {
      // Given
      final lessThan20hoursAgo = (const Duration(hours: 20)).inMilliseconds;
      final presence = CachedPresence(
        PresenceType.offline,
        lessThan20hoursAgo,
        "",
        false,
        "testuserid",
      );

      // WHEN
      await prepareTextWidget(presence, textWidgetKey, tester);

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals('online 20h ago'));
    });

    testWidgets(
        'GIVEN the presence time to be 5 days ago from present with currently active be false\n'
        'THEN should display the status as online 5d ago\n',
        (WidgetTester tester) async {
      // Given
      final lessThan5daysAgo = (const Duration(days: 5)).inMilliseconds;
      final presence = CachedPresence(
        PresenceType.offline,
        lessThan5daysAgo,
        "",
        false,
        "testuserid",
      );

      // WHEN
      await prepareTextWidget(presence, textWidgetKey, tester);

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals('online 5d ago'));
    });

    testWidgets(
        'GIVEN the presence time to be more than 30d ago from present with currently active be false\n'
        'THEN should display the status as a while ago\n',
        (WidgetTester tester) async {
      // Given
      final lessThan60daysAgo = (const Duration(days: 60)).inMilliseconds;
      final presence = CachedPresence(
        PresenceType.offline,
        lessThan60daysAgo,
        "",
        false,
        "testuserid",
      );

      // WHEN
      await prepareTextWidget(presence, textWidgetKey, tester);

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals('a while ago'));
    });

    testWidgets(
        'GIVEN the presence time to be more than 30d ago from present with currently active be false\n'
        'THEN should display the status as a while ago\n',
        (WidgetTester tester) async {
      // Given
      final lessThan60daysAgo = (const Duration(days: 60)).inMilliseconds;
      final presence = CachedPresence(
        PresenceType.offline,
        lessThan60daysAgo,
        "",
        false,
        "testuserid",
      );

      // WHEN
      await prepareTextWidget(presence, textWidgetKey, tester);

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals('a while ago'));
    });

    testWidgets(
        'GIVEN the presence to be unavailable \n'
        'THEN should display the status as offline\n',
        (WidgetTester tester) async {
      // Given
      final presence = CachedPresence(
        PresenceType.unavailable,
        null,
        "",
        false,
        "testuserid",
      );

      // WHEN
      await prepareTextWidget(presence, textWidgetKey, tester);

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals('Offline'));
    });

    testWidgets(
        'GIVEN the presence to be unavailable \n'
        'THEN should display the status as offline\n',
        (WidgetTester tester) async {
      // Given
      final presence = CachedPresence(
        PresenceType.unavailable,
        null,
        "",
        false,
        "testuserid",
      );

      // WHEN
      await prepareTextWidget(presence, textWidgetKey, tester);

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals('Offline'));
    });

    testWidgets(
        'GIVEN the presence to be null \n'
        'THEN should display the status as offline\n',
        (WidgetTester tester) async {
      // Given
      const presence = null;

      // WHEN
      await prepareTextWidget(presence, textWidgetKey, tester);

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals('Offline'));
    });
  });
}

Future<void> prepareTextWidget(
  CachedPresence? presence,
  ValueKey<String> textWidgetKey,
  WidgetTester tester,
) async {
  final client = MockClient();
  final room = Room(id: 'testid', client: client);

  // WHEN
  final textWidgetBuilder = Builder(
    builder: (BuildContext context) {
      final displayText = room.getLocalizedStatusDirectChat(presence, context);
      return Text(
        key: textWidgetKey,
        displayText,
      );
    },
  );

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      home: textWidgetBuilder,
    ),
  );
}
