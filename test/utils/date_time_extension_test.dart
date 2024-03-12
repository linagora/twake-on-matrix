import 'package:fluffychat/config/localizations/localization_service.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  group(
      '[localizedTimeShort TEST]\n'
      'GIVEN a Text widget\n'
      'USING localizedTimeShort\n', () {
    const textWidgetKey = ValueKey('textWidget');

    setUpAll(() {
      LocalizationService.currentLocale.value = const Locale('en', 'US');
    });

    testWidgets(
        'GIVEN the date time to display is today\n'
        'THEN should display the time in the format HH:mm\n',
        (WidgetTester tester) async {
      const expectedDisplayText = '12:05';
      final currentTime = DateTime(2022, 1, 1);
      final timeToTest = DateTime(2022, 1, 1, 12, 5);

      final textWidgetBuilder = Builder(
        builder: (BuildContext context) {
          final displayText = timeToTest.localizedTimeShort(
            context,
            currentTime: currentTime,
          );

          return Text(
            displayText,
            key: textWidgetKey,
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

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals(expectedDisplayText));
    });

    testWidgets(
        'GIVEN the date time to display is Monday of current week\n'
        'THEN should display the Monday\n', (WidgetTester tester) async {
      const expectedDisplayText = 'Monday';
      final currentTime = DateTime(2022, 1, 1);
      final timeToTest = DateTime(2021, 12, 27, 12, 5);

      final textWidgetBuilder = Builder(
        builder: (BuildContext context) {
          final displayText = timeToTest.localizedTimeShort(
            context,
            currentTime: currentTime,
          );

          return Text(
            displayText,
            key: textWidgetKey,
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

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals(expectedDisplayText));
    });

    testWidgets(
        'GIVEN the date time to display is Tuesday of current week\n'
        'THEN should display Tuesday\n', (WidgetTester tester) async {
      const expectedDisplayText = 'Tuesday';
      final currentTime = DateTime(2022, 1, 1);
      final timeToTest = DateTime(2021, 12, 28, 12, 5);

      final textWidgetBuilder = Builder(
        builder: (BuildContext context) {
          final displayText = timeToTest.localizedTimeShort(
            context,
            currentTime: currentTime,
          );

          return Text(
            displayText,
            key: textWidgetKey,
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

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals(expectedDisplayText));
    });

    testWidgets(
        'GIVEN the date time to display is Wednesday of current week\n'
        'THEN should display Wednesday\n', (WidgetTester tester) async {
      const expectedDisplayText = 'Wednesday';
      final currentTime = DateTime(2022, 1, 1);
      final timeToTest = DateTime(2021, 12, 29, 12, 5);

      final textWidgetBuilder = Builder(
        builder: (BuildContext context) {
          final displayText = timeToTest.localizedTimeShort(
            context,
            currentTime: currentTime,
          );

          return Text(
            displayText,
            key: textWidgetKey,
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

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals(expectedDisplayText));
    });

    testWidgets(
        'GIVEN the date time to display is Thursday of current week\n'
        'THEN should display Thursday\n', (WidgetTester tester) async {
      const expectedDisplayText = 'Thursday';
      final currentTime = DateTime(2022, 1, 1);
      final timeToTest = DateTime(2021, 12, 30, 12, 5);

      final textWidgetBuilder = Builder(
        builder: (BuildContext context) {
          final displayText = timeToTest.localizedTimeShort(
            context,
            currentTime: currentTime,
          );

          return Text(
            displayText,
            key: textWidgetKey,
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

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals(expectedDisplayText));
    });

    testWidgets(
        'GIVEN the date time to display is Friday of current week\n'
        'THEN should display Friday\n', (WidgetTester tester) async {
      const expectedDisplayText = 'Friday';
      final currentTime = DateTime(2022, 1, 1);
      final timeToTest = DateTime(2021, 12, 31, 12, 5);

      final textWidgetBuilder = Builder(
        builder: (BuildContext context) {
          final displayText = timeToTest.localizedTimeShort(
            context,
            currentTime: currentTime,
          );

          return Text(
            displayText,
            key: textWidgetKey,
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

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals(expectedDisplayText));
    });

    testWidgets(
        'GIVEN the date time to display is Saturday of current week\n'
        'THEN should display Saturday\n', (WidgetTester tester) async {
      const expectedDisplayText = 'Saturday';
      final currentTime = DateTime(2024, 2, 25);
      final timeToTest = DateTime(2024, 2, 24, 12, 5);

      final textWidgetBuilder = Builder(
        builder: (BuildContext context) {
          final displayText = timeToTest.localizedTimeShort(
            context,
            currentTime: currentTime,
          );

          return Text(
            displayText,
            key: textWidgetKey,
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

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals(expectedDisplayText));
    });

    testWidgets(
        'GIVEN the date time to display is Sunday of current week\n'
        'THEN should display Sunday\n', (WidgetTester tester) async {
      const expectedDisplayText = 'Sunday';
      final currentTime = DateTime(2022, 1, 1);
      final timeToTest = DateTime(2022, 1, 2, 12, 5);

      final textWidgetBuilder = Builder(
        builder: (BuildContext context) {
          final displayText = timeToTest.localizedTimeShort(
            context,
            currentTime: currentTime,
          );

          return Text(
            displayText,
            key: textWidgetKey,
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

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals(expectedDisplayText));
    });

    testWidgets(
        'GIVEN the current time is Sunday\n'
        'AND the date time to display is Friday of current week\n'
        'THEN should display Friday\n', (WidgetTester tester) async {
      const expectedDisplayText = 'Friday';
      final currentTime = DateTime(2024, 3, 3);
      final timeToTest = DateTime(2024, 3, 1, 12, 5);

      final textWidgetBuilder = Builder(
        builder: (BuildContext context) {
          final displayText = timeToTest.localizedTimeShort(
            context,
            currentTime: currentTime,
          );

          return Text(
            displayText,
            key: textWidgetKey,
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

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals(expectedDisplayText));
    });

    testWidgets(
        'GIVEN the current time is Sunday\n'
        'AND the date time to display is Saturday of current week\n'
        'THEN should display Saturday\n', (WidgetTester tester) async {
      const expectedDisplayText = 'Saturday';
      final currentTime = DateTime(2024, 3, 3);
      final timeToTest = DateTime(2024, 3, 2, 12, 5);

      final textWidgetBuilder = Builder(
        builder: (BuildContext context) {
          final displayText = timeToTest.localizedTimeShort(
            context,
            currentTime: currentTime,
          );

          return Text(
            displayText,
            key: textWidgetKey,
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

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals(expectedDisplayText));
    });

    testWidgets(
        'GIVEN current time is Sunday\n'
        'AND the date time to display is Monday of the next week\n'
        'THEN should display the date in the format MMM d\n',
        (WidgetTester tester) async {
      const expectedDisplayText = 'Mar 4';
      final currentTime = DateTime(2024, 3, 3);
      final timeToTest = DateTime(2024, 3, 4, 12, 5);

      final textWidgetBuilder = Builder(
        builder: (BuildContext context) {
          final displayText = timeToTest.localizedTimeShort(
            context,
            currentTime: currentTime,
          );

          return Text(
            displayText,
            key: textWidgetKey,
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

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals(expectedDisplayText));
    });

    testWidgets(
        'GIVEN current time is Sunday\n'
        'AND the date time to display is Tuesday of the next week\n'
        'THEN should display the date in the format MMM d\n',
        (WidgetTester tester) async {
      const expectedDisplayText = 'Mar 5';
      final currentTime = DateTime(2024, 3, 3);
      final timeToTest = DateTime(2024, 3, 5, 12, 5);

      final textWidgetBuilder = Builder(
        builder: (BuildContext context) {
          final displayText = timeToTest.localizedTimeShort(
            context,
            currentTime: currentTime,
          );

          return Text(
            displayText,
            key: textWidgetKey,
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

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals(expectedDisplayText));
    });

    testWidgets(
        'GIVEN the date time to display is not in the same week\n'
        'AND in the same year\n'
        'THEN should display the date in the format MMM d\n',
        (WidgetTester tester) async {
      const expectedDisplayText = 'Feb 22';
      final currentTime = DateTime(2024, 2, 28);
      final timeToTest = DateTime(2024, 2, 22, 12, 5);

      final textWidgetBuilder = Builder(
        builder: (BuildContext context) {
          final displayText = timeToTest.localizedTimeShort(
            context,
            currentTime: currentTime,
          );

          return Text(
            displayText,
            key: textWidgetKey,
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

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals(expectedDisplayText));
    });

    testWidgets(
        'GIVEN the date time to display is not in the same week\n'
        'AND in the same year\n'
        'THEN should display the date in the format MMM d\n',
        (WidgetTester tester) async {
      const expectedDisplayText = 'Feb 25';
      final currentTime = DateTime(2024, 2, 28);
      final timeToTest = DateTime(2024, 2, 25, 12, 5);

      final textWidgetBuilder = Builder(
        builder: (BuildContext context) {
          final displayText = timeToTest.localizedTimeShort(
            context,
            currentTime: currentTime,
          );

          return Text(
            displayText,
            key: textWidgetKey,
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

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals(expectedDisplayText));
    });

    testWidgets(
        'GIVEN the date time to display is not in the same week\n'
        'AND in the same year\n'
        'THEN should display the date in the format MMM d\n',
        (WidgetTester tester) async {
      const expectedDisplayText = 'Feb 24';
      final currentTime = DateTime(2024, 2, 28);
      final timeToTest = DateTime(2024, 2, 24, 12, 5);

      final textWidgetBuilder = Builder(
        builder: (BuildContext context) {
          final displayText = timeToTest.localizedTimeShort(
            context,
            currentTime: currentTime,
          );

          return Text(
            displayText,
            key: textWidgetKey,
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

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals(expectedDisplayText));
    });

    testWidgets(
        'GIVEN the date time to display is not in the same week\n'
        'AND in the same year\n'
        'THEN should display the date in the format MMM d\n',
        (WidgetTester tester) async {
      const expectedDisplayText = 'Feb 25';
      final currentTime = DateTime(2024, 2, 26);
      final timeToTest = DateTime(2024, 2, 25, 12, 5);

      final textWidgetBuilder = Builder(
        builder: (BuildContext context) {
          final displayText = timeToTest.localizedTimeShort(
            context,
            currentTime: currentTime,
          );

          return Text(
            displayText,
            key: textWidgetKey,
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

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals(expectedDisplayText));
    });

    testWidgets(
        'GIVEN the date time to display is not in the same week\n'
        'AND in the same year\n'
        'THEN should display the date in the format MMM d\n',
        (WidgetTester tester) async {
      const expectedDisplayText = 'Feb 24';
      final currentTime = DateTime(2024, 2, 26);
      final timeToTest = DateTime(2024, 2, 24, 12, 5);

      final textWidgetBuilder = Builder(
        builder: (BuildContext context) {
          final displayText = timeToTest.localizedTimeShort(
            context,
            currentTime: currentTime,
          );

          return Text(
            displayText,
            key: textWidgetKey,
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

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals(expectedDisplayText));
    });

    testWidgets(
        'GIVEN the date time to display is not in the same week\n'
        'AND in the same year\n'
        'THEN should display the date in the format MMM d\n',
        (WidgetTester tester) async {
      const expectedDisplayText = 'Feb 23';
      final currentTime = DateTime(2024, 2, 26);
      final timeToTest = DateTime(2024, 2, 23, 12, 5);

      final textWidgetBuilder = Builder(
        builder: (BuildContext context) {
          final displayText = timeToTest.localizedTimeShort(
            context,
            currentTime: currentTime,
          );

          return Text(
            displayText,
            key: textWidgetKey,
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

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals(expectedDisplayText));
    });

    testWidgets(
        'GIVEN the date time to display is not in the same week\n'
        'AND not in the same year\n'
        'THEN should display the date in the format dd/MM/yy\n',
        (WidgetTester tester) async {
      const expectedDisplayText = '22/02/23';
      final currentTime = DateTime(2024, 2, 28);
      final timeToTest = DateTime(2023, 2, 22, 12, 5);

      final textWidgetBuilder = Builder(
        builder: (BuildContext context) {
          final displayText = timeToTest.localizedTimeShort(
            context,
            currentTime: currentTime,
          );

          return Text(
            displayText,
            key: textWidgetKey,
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

      final textWidgetFinder = find.byKey(textWidgetKey);

      expect(textWidgetFinder, findsOneWidget);

      final Text textWidget = tester.widget(textWidgetFinder) as Text;

      expect(textWidget.data, isNotNull);

      expect(textWidget.data, equals(expectedDisplayText));
    });
  });

  group('[isInCurrentWeek TEST]', () {
    final currentTime = DateTime(2022, 1, 1);
    test(
        'GIVEN time to check is in current week\n'
        'THEN return true', () {
      final timeToTest = DateTime(2021, 12, 27, 12, 5);

      final result = timeToTest.isInCurrentWeek(currentTime: currentTime);

      expect(result, isTrue);
    });

    test(
        'GIVEN time to check is not in current week\n'
        'THEN return false', () {
      final timeToTest = DateTime(2021, 12, 20, 12, 5);

      final result = timeToTest.isInCurrentWeek(currentTime: currentTime);

      expect(result, isFalse);
    });
  });

  group(
    '[relativeTime TEST]\n'
    'GIVEN a Text widget\n'
    'USING relativeTime\n',
    () {
      const textWidgetKey = ValueKey('textWidget');
      group('GIVEN locale is French', () {
        setUpAll(() {
          LocalizationService.currentLocale.value = const Locale('fr', 'FR');
        });

        testWidgets(
            'GIVEN the date time to display is today\n'
            "THEN should display Aujourd'hui\n", (WidgetTester tester) async {
          const expectedDisplayText = "Aujourd'hui";
          final currentTime = DateTime(2024, 2, 28);
          final timeToTest = DateTime(2024, 2, 28);

          final textWidgetBuilder = Builder(
            builder: (BuildContext context) {
              final displayText = timeToTest.relativeTime(
                context,
                currentTime: currentTime,
              );

              return Text(
                displayText,
                key: textWidgetKey,
              );
            },
          );

          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('fr', 'FR'),
              localizationsDelegates: L10n.localizationsDelegates,
              supportedLocales: L10n.supportedLocales,
              home: textWidgetBuilder,
            ),
          );

          final textWidgetFinder = find.byKey(textWidgetKey);

          expect(textWidgetFinder, findsOneWidget);

          final Text textWidget = tester.widget(textWidgetFinder) as Text;

          expect(textWidget.data, isNotNull);

          expect(textWidget.data, equals(expectedDisplayText));
        });

        testWidgets(
            'GIVEN the date time to display is yesterday\n'
            'THEN should display Hier\n', (WidgetTester tester) async {
          const expectedDisplayText = 'Hier';
          final currentTime = DateTime(2024, 2, 28);
          final timeToTest = DateTime(2024, 2, 27);

          final textWidgetBuilder = Builder(
            builder: (BuildContext context) {
              final displayText = timeToTest.relativeTime(
                context,
                currentTime: currentTime,
              );

              return Text(
                displayText,
                key: textWidgetKey,
              );
            },
          );

          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('fr', 'FR'),
              localizationsDelegates: L10n.localizationsDelegates,
              supportedLocales: L10n.supportedLocales,
              home: textWidgetBuilder,
            ),
          );

          final textWidgetFinder = find.byKey(textWidgetKey);

          expect(textWidgetFinder, findsOneWidget);

          final Text textWidget = tester.widget(textWidgetFinder) as Text;

          expect(textWidget.data, isNotNull);

          expect(textWidget.data, equals(expectedDisplayText));
        });

        testWidgets(
            'GIVEN the date time to display is not today or yesterday but in the same year\n'
            'THEN should display the date in the format MMMM d\n',
            (WidgetTester tester) async {
          const expectedDisplayText = 'Janvier 15';
          final currentTime = DateTime(2024, 2, 28);
          final timeToTest = DateTime(2024, 1, 15);

          final textWidgetBuilder = Builder(
            builder: (BuildContext context) {
              final displayText = timeToTest.relativeTime(
                context,
                currentTime: currentTime,
              );

              return Text(
                displayText,
                key: textWidgetKey,
              );
            },
          );

          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('fr', 'FR'),
              localizationsDelegates: L10n.localizationsDelegates,
              supportedLocales: L10n.supportedLocales,
              home: textWidgetBuilder,
            ),
          );

          final textWidgetFinder = find.byKey(textWidgetKey);

          expect(textWidgetFinder, findsOneWidget);

          final Text textWidget = tester.widget(textWidgetFinder) as Text;

          expect(textWidget.data, isNotNull);

          expect(textWidget.data, equals(expectedDisplayText));
        });

        testWidgets(
            'GIVEN the date time to display is not in the same year\n'
            'THEN should display the date in the format MMMM d, y\n',
            (WidgetTester tester) async {
          const expectedDisplayText = 'Janvier 15, 2023';
          final currentTime = DateTime(2024, 2, 28);
          final timeToTest = DateTime(2023, 1, 15);

          final textWidgetBuilder = Builder(
            builder: (BuildContext context) {
              final displayText = timeToTest.relativeTime(
                context,
                currentTime: currentTime,
              );

              return Text(
                displayText,
                key: textWidgetKey,
              );
            },
          );

          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('fr', 'FR'),
              localizationsDelegates: L10n.localizationsDelegates,
              supportedLocales: L10n.supportedLocales,
              home: textWidgetBuilder,
            ),
          );

          final textWidgetFinder = find.byKey(textWidgetKey);

          expect(textWidgetFinder, findsOneWidget);

          final Text textWidget = tester.widget(textWidgetFinder) as Text;

          expect(textWidget.data, isNotNull);

          expect(textWidget.data, equals(expectedDisplayText));
        });
      });

      group('GIVEN locale is Russia', () {
        setUpAll(() {
          LocalizationService.currentLocale.value = const Locale('ru', 'RU');
        });

        testWidgets(
            'GIVEN the date time to display is today\n'
            "THEN should display Сегодня\n", (WidgetTester tester) async {
          const expectedDisplayText = "Сегодня";
          final currentTime = DateTime(2024, 2, 28);
          final timeToTest = DateTime(2024, 2, 28);

          final textWidgetBuilder = Builder(
            builder: (BuildContext context) {
              final displayText = timeToTest.relativeTime(
                context,
                currentTime: currentTime,
              );

              return Text(
                displayText,
                key: textWidgetKey,
              );
            },
          );

          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('ru', 'RU'),
              localizationsDelegates: L10n.localizationsDelegates,
              supportedLocales: L10n.supportedLocales,
              home: textWidgetBuilder,
            ),
          );

          final textWidgetFinder = find.byKey(textWidgetKey);

          expect(textWidgetFinder, findsOneWidget);

          final Text textWidget = tester.widget(textWidgetFinder) as Text;

          expect(textWidget.data, isNotNull);

          expect(textWidget.data, equals(expectedDisplayText));
        });

        testWidgets(
            'GIVEN the date time to display is yesterday\n'
            'THEN should display Вчера\n', (WidgetTester tester) async {
          const expectedDisplayText = 'Вчера';
          final currentTime = DateTime(2024, 2, 28);
          final timeToTest = DateTime(2024, 2, 27);

          final textWidgetBuilder = Builder(
            builder: (BuildContext context) {
              final displayText = timeToTest.relativeTime(
                context,
                currentTime: currentTime,
              );

              return Text(
                displayText,
                key: textWidgetKey,
              );
            },
          );

          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('ru', 'RU'),
              localizationsDelegates: L10n.localizationsDelegates,
              supportedLocales: L10n.supportedLocales,
              home: textWidgetBuilder,
            ),
          );

          final textWidgetFinder = find.byKey(textWidgetKey);

          expect(textWidgetFinder, findsOneWidget);

          final Text textWidget = tester.widget(textWidgetFinder) as Text;

          expect(textWidget.data, isNotNull);

          expect(textWidget.data, equals(expectedDisplayText));
        });

        testWidgets(
            'GIVEN the date time to display is not today or yesterday but in the same year\n'
            'THEN should display the date in the format MMMM d\n',
            (WidgetTester tester) async {
          const expectedDisplayText = 'Января 15';
          final currentTime = DateTime(2024, 2, 28);
          final timeToTest = DateTime(2024, 1, 15);

          final textWidgetBuilder = Builder(
            builder: (BuildContext context) {
              final displayText = timeToTest.relativeTime(
                context,
                currentTime: currentTime,
              );

              return Text(
                displayText,
                key: textWidgetKey,
              );
            },
          );

          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('ru', 'RU'),
              localizationsDelegates: L10n.localizationsDelegates,
              supportedLocales: L10n.supportedLocales,
              home: textWidgetBuilder,
            ),
          );

          final textWidgetFinder = find.byKey(textWidgetKey);

          expect(textWidgetFinder, findsOneWidget);

          final Text textWidget = tester.widget(textWidgetFinder) as Text;

          expect(textWidget.data, isNotNull);

          expect(textWidget.data, equals(expectedDisplayText));
        });

        testWidgets(
            'GIVEN the date time to display is not in the same year\n'
            'THEN should display the date in the format MMMM d, y\n',
            (WidgetTester tester) async {
          const expectedDisplayText = 'Января 15, 2023';
          final currentTime = DateTime(2024, 2, 28);
          final timeToTest = DateTime(2023, 1, 15);

          final textWidgetBuilder = Builder(
            builder: (BuildContext context) {
              final displayText = timeToTest.relativeTime(
                context,
                currentTime: currentTime,
              );

              return Text(
                displayText,
                key: textWidgetKey,
              );
            },
          );

          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('ru', 'RU'),
              localizationsDelegates: L10n.localizationsDelegates,
              supportedLocales: L10n.supportedLocales,
              home: textWidgetBuilder,
            ),
          );

          final textWidgetFinder = find.byKey(textWidgetKey);

          expect(textWidgetFinder, findsOneWidget);

          final Text textWidget = tester.widget(textWidgetFinder) as Text;

          expect(textWidget.data, isNotNull);

          expect(textWidget.data, equals(expectedDisplayText));
        });
      });

      group('GIVEN locale is Vietnam', () {
        setUpAll(() {
          LocalizationService.currentLocale.value = const Locale('vi', 'VN');
        });

        testWidgets(
            'GIVEN the date time to display is today\n'
            "THEN should display Hôm nay\n", (WidgetTester tester) async {
          const expectedDisplayText = "Hôm nay";
          final currentTime = DateTime(2024, 2, 28);
          final timeToTest = DateTime(2024, 2, 28);

          final textWidgetBuilder = Builder(
            builder: (BuildContext context) {
              final displayText = timeToTest.relativeTime(
                context,
                currentTime: currentTime,
              );

              return Text(
                displayText,
                key: textWidgetKey,
              );
            },
          );

          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('vi', 'VN'),
              localizationsDelegates: L10n.localizationsDelegates,
              supportedLocales: L10n.supportedLocales,
              home: textWidgetBuilder,
            ),
          );

          final textWidgetFinder = find.byKey(textWidgetKey);

          expect(textWidgetFinder, findsOneWidget);

          final Text textWidget = tester.widget(textWidgetFinder) as Text;

          expect(textWidget.data, isNotNull);

          expect(textWidget.data, equals(expectedDisplayText));
        });

        testWidgets(
            'GIVEN the date time to display is yesterday\n'
            'THEN should display Hôm qua\n', (WidgetTester tester) async {
          const expectedDisplayText = 'Hôm qua';
          final currentTime = DateTime(2024, 2, 28);
          final timeToTest = DateTime(2024, 2, 27);

          final textWidgetBuilder = Builder(
            builder: (BuildContext context) {
              final displayText = timeToTest.relativeTime(
                context,
                currentTime: currentTime,
              );

              return Text(
                displayText,
                key: textWidgetKey,
              );
            },
          );

          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('vi', 'VN'),
              localizationsDelegates: L10n.localizationsDelegates,
              supportedLocales: L10n.supportedLocales,
              home: textWidgetBuilder,
            ),
          );

          final textWidgetFinder = find.byKey(textWidgetKey);

          expect(textWidgetFinder, findsOneWidget);

          final Text textWidget = tester.widget(textWidgetFinder) as Text;

          expect(textWidget.data, isNotNull);

          expect(textWidget.data, equals(expectedDisplayText));
        });

        testWidgets(
            'GIVEN the date time to display is not today or yesterday but in the same year\n'
            'THEN should display the date in the format MMMM d\n',
            (WidgetTester tester) async {
          const expectedDisplayText = 'Tháng 1 15';
          final currentTime = DateTime(2024, 2, 28);
          final timeToTest = DateTime(2024, 1, 15);

          final textWidgetBuilder = Builder(
            builder: (BuildContext context) {
              final displayText = timeToTest.relativeTime(
                context,
                currentTime: currentTime,
              );

              return Text(
                displayText,
                key: textWidgetKey,
              );
            },
          );

          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('vi', 'VN'),
              localizationsDelegates: L10n.localizationsDelegates,
              supportedLocales: L10n.supportedLocales,
              home: textWidgetBuilder,
            ),
          );

          final textWidgetFinder = find.byKey(textWidgetKey);

          expect(textWidgetFinder, findsOneWidget);

          final Text textWidget = tester.widget(textWidgetFinder) as Text;

          expect(textWidget.data, isNotNull);

          expect(textWidget.data, equals(expectedDisplayText));
        });

        testWidgets(
            'GIVEN the date time to display is not in the same year\n'
            'THEN should display the date in the format MMMM d, y\n',
            (WidgetTester tester) async {
          const expectedDisplayText = 'Tháng 1 15, 2023';
          final currentTime = DateTime(2024, 2, 28);
          final timeToTest = DateTime(2023, 1, 15);

          final textWidgetBuilder = Builder(
            builder: (BuildContext context) {
              final displayText = timeToTest.relativeTime(
                context,
                currentTime: currentTime,
              );

              return Text(
                displayText,
                key: textWidgetKey,
              );
            },
          );

          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('vi', 'VN'),
              localizationsDelegates: L10n.localizationsDelegates,
              supportedLocales: L10n.supportedLocales,
              home: textWidgetBuilder,
            ),
          );

          final textWidgetFinder = find.byKey(textWidgetKey);

          expect(textWidgetFinder, findsOneWidget);

          final Text textWidget = tester.widget(textWidgetFinder) as Text;

          expect(textWidget.data, isNotNull);

          expect(textWidget.data, equals(expectedDisplayText));
        });
      });

      group('GIVEN locale is English', () {
        setUpAll(() {
          LocalizationService.currentLocale.value = const Locale('en', 'US');
        });

        testWidgets(
            'GIVEN the date time to display is today\n'
            "THEN should display Today\n", (WidgetTester tester) async {
          const expectedDisplayText = "Today";
          final currentTime = DateTime(2024, 2, 28);
          final timeToTest = DateTime(2024, 2, 28);

          final textWidgetBuilder = Builder(
            builder: (BuildContext context) {
              final displayText = timeToTest.relativeTime(
                context,
                currentTime: currentTime,
              );

              return Text(
                displayText,
                key: textWidgetKey,
              );
            },
          );

          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('en', 'US'),
              localizationsDelegates: L10n.localizationsDelegates,
              supportedLocales: L10n.supportedLocales,
              home: textWidgetBuilder,
            ),
          );

          final textWidgetFinder = find.byKey(textWidgetKey);

          expect(textWidgetFinder, findsOneWidget);

          final Text textWidget = tester.widget(textWidgetFinder) as Text;

          expect(textWidget.data, isNotNull);

          expect(textWidget.data, equals(expectedDisplayText));
        });

        testWidgets(
            'GIVEN the date time to display is yesterday\n'
            'THEN should display Yesterday\n', (WidgetTester tester) async {
          const expectedDisplayText = 'Yesterday';
          final currentTime = DateTime(2024, 2, 28);
          final timeToTest = DateTime(2024, 2, 27);

          final textWidgetBuilder = Builder(
            builder: (BuildContext context) {
              final displayText = timeToTest.relativeTime(
                context,
                currentTime: currentTime,
              );

              return Text(
                displayText,
                key: textWidgetKey,
              );
            },
          );

          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('en', 'US'),
              localizationsDelegates: L10n.localizationsDelegates,
              supportedLocales: L10n.supportedLocales,
              home: textWidgetBuilder,
            ),
          );

          final textWidgetFinder = find.byKey(textWidgetKey);

          expect(textWidgetFinder, findsOneWidget);

          final Text textWidget = tester.widget(textWidgetFinder) as Text;

          expect(textWidget.data, isNotNull);

          expect(textWidget.data, equals(expectedDisplayText));
        });

        testWidgets(
            'GIVEN the date time to display is not today or yesterday but in the same year\n'
            'THEN should display the date in the format MMMM d\n',
            (WidgetTester tester) async {
          const expectedDisplayText = 'January 15';
          final currentTime = DateTime(2024, 2, 28);
          final timeToTest = DateTime(2024, 1, 15);

          final textWidgetBuilder = Builder(
            builder: (BuildContext context) {
              final displayText = timeToTest.relativeTime(
                context,
                currentTime: currentTime,
              );

              return Text(
                displayText,
                key: textWidgetKey,
              );
            },
          );

          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('en', 'US'),
              localizationsDelegates: L10n.localizationsDelegates,
              supportedLocales: L10n.supportedLocales,
              home: textWidgetBuilder,
            ),
          );

          final textWidgetFinder = find.byKey(textWidgetKey);

          expect(textWidgetFinder, findsOneWidget);

          final Text textWidget = tester.widget(textWidgetFinder) as Text;

          expect(textWidget.data, isNotNull);

          expect(textWidget.data, equals(expectedDisplayText));
        });

        testWidgets(
            'GIVEN the date time to display is not in the same year\n'
            'THEN should display the date in the format MMMM d, y\n',
            (WidgetTester tester) async {
          const expectedDisplayText = 'January 15, 2023';
          final currentTime = DateTime(2024, 2, 28);
          final timeToTest = DateTime(2023, 1, 15);

          final textWidgetBuilder = Builder(
            builder: (BuildContext context) {
              final displayText = timeToTest.relativeTime(
                context,
                currentTime: currentTime,
              );

              return Text(
                displayText,
                key: textWidgetKey,
              );
            },
          );

          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('en', 'US'),
              localizationsDelegates: L10n.localizationsDelegates,
              supportedLocales: L10n.supportedLocales,
              home: textWidgetBuilder,
            ),
          );

          final textWidgetFinder = find.byKey(textWidgetKey);

          expect(textWidgetFinder, findsOneWidget);

          final Text textWidget = tester.widget(textWidgetFinder) as Text;

          expect(textWidget.data, isNotNull);

          expect(textWidget.data, equals(expectedDisplayText));
        });
      });
    },
  );
}
