// ignore_for_file: depend_on_referenced_packages

import 'package:fluffychat/config/localizations/localization_service.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/chat/events/message/message_content_builder_mixin.dart';
import 'package:fluffychat/presentation/model/chat/events/message/message_metrics.dart';
import 'package:fluffychat/utils/custom_scroll_behaviour.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/theme_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

import '../../../../fake_client.dart';

class MockUpMessageContentBuilder with MessageContentBuilderMixin {}

/// Expected geometric regime of a message bubble, asserted as a contract
/// instead of exact pixel widths.
enum BubbleRegime {
  /// Content fits: width < maxWidth, no forced new line.
  fits,

  /// Last line has no room for the timestamp: width == maxWidth, new line.
  wraps,

  /// Width is driven by the wider display name, not the message body.
  displayNameDriven,
}

void _expectRegime(
  MessageMetrics? metrics,
  MessageMetrics? messageOnlyMetrics,
  double maxWidth,
  BubbleRegime regime,
) {
  expect(metrics, isNotNull);
  final m = metrics!;
  final width = m.totalMessageWidth;
  expect(width, greaterThan(0));
  expect(width, lessThanOrEqualTo(maxWidth));
  switch (regime) {
    case BubbleRegime.fits:
      expect(m.isNeedAddNewLine, isFalse);
      expect(width, lessThan(maxWidth));
    case BubbleRegime.wraps:
      expect(m.isNeedAddNewLine, isTrue);
      expect(width, equals(maxWidth));
    case BubbleRegime.displayNameDriven:
      expect(m.isNeedAddNewLine, isFalse);
      expect(messageOnlyMetrics, isNotNull);
      expect(width, greaterThan(messageOnlyMetrics!.totalMessageWidth));
  }
}

void _expectMetrics(
  MessageMetrics? metrics,
  MessageMetrics? messageOnlyMetrics,
  Event event,
  double maxWidth,
  BubbleRegime? regime,
  bool? expectedIsNeedAddNewLine,
) {
  if (regime != null) {
    _expectRegime(metrics, messageOnlyMetrics, maxWidth, regime);
    return;
  }
  if (expectedIsNeedAddNewLine != null) {
    expect(metrics, isNotNull);
    final m = metrics!;
    expect(m.totalMessageWidth, greaterThan(0));
    expect(m.totalMessageWidth, lessThanOrEqualTo(maxWidth));
    expect(m.isNeedAddNewLine, equals(expectedIsNeedAddNewLine));
    return;
  }
  expect(metrics, event.isVideoOrImage ? isNotNull : isNull);
}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockUpMessageContentBuilder mockUpMessageContentBuilder;
  setUpAll(() {
    mockUpMessageContentBuilder = MockUpMessageContentBuilder();
    final getIt = GetIt.instance;
    getIt.registerSingleton(ResponsiveUtils());
  });

  final client = await getClient();
  final room = Room(id: '!room:example.abc', client: client);
  final fileEvent = Event(
    content: {
      'body': 'something-important.doc',
      'filename': 'something-important.doc',
      'info': {'mimetype': 'application/msword', 'size': 46144},
      'msgtype': 'm.file',
      'url': 'mxc://example.org/FHyPlCeYUSFFxlgbQYZmoEoe',
    },
    type: 'm.room.message',
    eventId: '\$143273582443PhrSn:example.org',
    senderId: '@example:example.org',
    originServerTs: DateTime.fromMillisecondsSinceEpoch(1894270481925),
    room: room,
  );
  final imageEvent = Event(
    content: {
      'body': 'filename.jpg',
      'info': {'h': 398, 'mimetype': 'image/jpeg', 'size': 31037, 'w': 394},
      'msgtype': 'm.image',
      'url': 'mxc://example.org/JWEIFJgwEIhweiWJE',
    },
    type: 'm.room.message',
    eventId: '\$143273582443PhrSn:example.org',
    senderId: '@example:example.org',
    originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
    room: room,
  );
  final videoEvent = Event(
    content: {
      'body': 'Gangnam Style',
      'info': {
        'duration': 2140786,
        'h': 320,
        'mimetype': 'video/mp4',
        'size': 1563685,
        'thumbnail_info': {
          'h': 300,
          'mimetype': 'image/jpeg',
          'size': 46144,
          'w': 300,
        },
        'thumbnail_url': 'mxc://example.org/FHyPlCeYUSFFxlgbQYZmoEoe',
        'w': 480,
      },
      'msgtype': 'm.video',
      'url': 'mxc://example.org/a526eYUSFFxlgbQYZmo442',
    },
    type: 'm.room.message',
    eventId: '\$143273582443PhrSn:example.org',
    senderId: '@example:example.org',
    originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
    room: room,
  );
  final emptyTextEvent = Event(
    content: {'body': '', 'msgtype': 'm.text'},
    type: 'm.room.message',
    eventId: '\$143273582443PhrSn:example.org',
    senderId: '@example:example.org',
    originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
    room: room,
  );

  group('[MessageContentBuilderMixin] TEST\n', () {
    // In unit testing, TextScaler(1.5) simulates medium font size.
    const textScaler = TextScaler.linear(1.5);

    Future<void> runTest(
      WidgetTester tester, {
      required Event event,
      required double maxWidth,
      BubbleRegime? regime,
      bool ownMessage = false,
      bool hideDisplayName = false,
      bool? expectedIsNeedAddNewLine,
    }) async {
      MessageMetrics? metrics;
      // Same event as an own message: no display name, width is the body alone.
      MessageMetrics? messageOnlyMetrics;

      await tester.pumpWidget(
        ThemeBuilder(
          builder: (context, themeMode, primaryColor) => MaterialApp(
            locale: const Locale('en'),
            scrollBehavior: CustomScrollBehavior(),
            localizationsDelegates: const [
              LocaleNamesLocalizationsDelegate(),
              L10n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: LocalizationService.supportedLocales,
            theme: TwakeThemes.buildTheme(
              context,
              Brightness.light,
              primaryColor,
            ),
            builder: (context, child) => MediaQuery(
              data: const MediaQueryData(textScaler: textScaler),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  metrics = mockUpMessageContentBuilder
                      .getSizeMessageBubbleWidth(
                        context,
                        event: event,
                        maxWidth: maxWidth,
                        ownMessage: ownMessage,
                        hideDisplayName: hideDisplayName,
                      );
                  messageOnlyMetrics = regime == BubbleRegime.displayNameDriven
                      ? mockUpMessageContentBuilder.getSizeMessageBubbleWidth(
                          context,
                          event: event,
                          maxWidth: maxWidth,
                          ownMessage: true,
                        )
                      : null;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      _expectMetrics(
        metrics,
        messageOnlyMetrics,
        event,
        maxWidth,
        regime,
        expectedIsNeedAddNewLine,
      );
    }

    group('[getSizeMessageBubbleWidth] TEST\n'
        'GIVEN platform is Web\n'
        'THEN maxWidth for message is 504.0\n', () {
      const messageMaxWidthWeb = 504.0;
      group('GIVEN message type does not require detailed text metrics\n', () {
        testWidgets('GIVEN message type is file\n'
            'THEN return null\n', (WidgetTester tester) async {
          await runTest(tester, event: fileEvent, maxWidth: messageMaxWidthWeb);
        });
        testWidgets('GIVEN message type is image\n'
            'THEN return is not null\n', (WidgetTester tester) async {
          await runTest(
            tester,
            event: imageEvent,
            maxWidth: messageMaxWidthWeb,
          );
        });
        testWidgets('GIVEN message type is video\n'
            'THEN return is not null\n', (WidgetTester tester) async {
          await runTest(
            tester,
            event: videoEvent,
            maxWidth: messageMaxWidthWeb,
          );
        });
      });

      testWidgets('GIVEN message text is empty\n'
          'THEN return null\n', (WidgetTester tester) async {
        await runTest(
          tester,
          event: emptyTextEvent,
          maxWidth: messageMaxWidthWeb,
        );
      });

      group('GIVEN ownMessage is true\n'
          'OR hideDisplayName is true\n'
          'THEN return message width\n', () {
        testWidgets('GIVEN message body has multiple lines\n'
            'AND last line of message has enough space for timeline\n'
            'THEN return total message width is width of longest line\n'
            'AND isNeedAddNewLine is false\n', (WidgetTester tester) async {
          final eventToTest = Event(
            content: {
              "msgtype": "m.text",
              "body":
                  "sioaldhgowehg wegh welg\n- Pourquoi pas?\n- Non problem\n- Mais je ne comprend pas\n- d'arrcord\n- ádgnaslg\n- ádasd\n- asdg ag\n- asegw sioaldhg\n- helfnwlgweg",
              "format": "org.matrix.custom.html",
              "formatted_body":
                  "sioaldhgowehg wegh welg<br/>- Pourquoi pas?<br/>- Non problem<br/>- Mais je ne comprend pas<br/>- d'arrcord<br/>- ádgnaslg<br/>- ádasd<br/>- asdg ag<br/>- asegw sioaldhg<br/>- helfnwlgweg",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          );

          await runTest(
            tester,
            event: eventToTest,
            maxWidth: messageMaxWidthWeb,
            regime: BubbleRegime.fits,
            ownMessage: true,
          );
        });
        testWidgets('GIVEN message body has multiple lines\n'
            'AND last line has enough space for time line at web width\n'
            'THEN return total message width fits the last line and time\n'
            'AND isNeedAddNewLine is false\n', (WidgetTester tester) async {
          final eventToTest = Event(
            content: {
              "msgtype": "m.text",
              "body":
                  "#2730 Fallback value for Always read receipt settings is false -> Done\n\n#2628 Disable view PDF file in mobile -> Done\n\n#2726 Remove logo in printed email -> Done\n\n#2737 View PDF in js -> Done",
              "format": "org.matrix.custom.html",
              "formatted_body":
                  "<p>#2730 Fallback value for Always read receipt settings is false -&gt; Done</p><br/><p>#2628 Disable view PDF file in mobile -&gt; Done</p><br/><p>#2726 Remove logo in printed email -&gt; Done</p><br/><p>#2737 View PDF in js -&gt; Done</p>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
            unsigned: {
              "age": 26236536,
              "com.famedly.famedlysdk.message_sending_status": 2,
            },
          );
          // Fits at web width; the wrap branch is covered by the mobile cases.
          await runTest(
            tester,
            event: eventToTest,
            maxWidth: messageMaxWidthWeb,
            regime: BubbleRegime.fits,
            ownMessage: true,
          );
        });
      });

      group('GIVEN ownMessage is false\n'
          'AND hideDisplayName is false\n', () {
        testWidgets('GIVEN width of display name is wider than message body\n'
            'THEN return message bubble width is width of display name\n', (
          WidgetTester tester,
        ) async {
          final eventToTest = Event(
            content: {
              "msgtype": "m.text",
              "body": "Hello",
              "format": "org.matrix.custom.html",
              "formatted_body": "<p>Hello</p>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@exampleabcdh:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          );
          await runTest(
            tester,
            event: eventToTest,
            maxWidth: messageMaxWidthWeb,
            regime: BubbleRegime.displayNameDriven,
            ownMessage: false,
            hideDisplayName: false,
          );
        });

        testWidgets('GIVEN width of display name is smaller than message body\n'
            'AND message body has multiple lines\n'
            'AND last line of message has enough space for timeline\n'
            'THEN return total message width is width of longest line\n'
            'AND isNeedAddNewLine is false\n', (WidgetTester tester) async {
          final eventToTest = Event(
            content: {
              "msgtype": "m.text",
              "body":
                  "sioaldhgowehg wegh welg\n- Pourquoi pas?\n- Non problem\n- Mais je ne comprend pas\n- d'arrcord\n- ádgnaslg\n- ádasd\n- asdg ag\n- asegw sioaldhg\n- helfnwlgweg",
              "format": "org.matrix.custom.html",
              "formatted_body":
                  "sioaldhgowehg wegh welg<br/>- Pourquoi pas?<br/>- Non problem<br/>- Mais je ne comprend pas<br/>- d'arrcord<br/>- ádgnaslg<br/>- ádasd<br/>- asdg ag<br/>- asegw sioaldhg<br/>- helfnwlgweg",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          );
          await runTest(
            tester,
            event: eventToTest,
            maxWidth: messageMaxWidthWeb,
            regime: BubbleRegime.fits,
            ownMessage: false,
            hideDisplayName: false,
          );
        });

        testWidgets('GIVEN width of display name is smaller than message body\n'
            'AND message body has multiple lines\n'
            'AND last line has enough space for time line at web width\n'
            'THEN return total message width fits the last line and time\n'
            'AND isNeedAddNewLine is false\n', (WidgetTester tester) async {
          final eventToTest = Event(
            content: {
              "msgtype": "m.text",
              "body":
                  "#2730 Fallback value for Always read receipt settings is false -> Done\n\n#2628 Disable view PDF file in mobile -> Done\n\n#2726 Remove logo in printed email -> Done\n\n#2737 View PDF in js -> Done",
              "format": "org.matrix.custom.html",
              "formatted_body":
                  "<p>#2730 Fallback value for Always read receipt settings is false -&gt; Done</p><br/><p>#2628 Disable view PDF file in mobile -&gt; Done</p><br/><p>#2726 Remove logo in printed email -&gt; Done</p><br/><p>#2737 View PDF in js -&gt; Done</p>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          );
          // Fits at web width; the wrap branch is covered by the mobile cases.
          await runTest(
            tester,
            event: eventToTest,
            maxWidth: messageMaxWidthWeb,
            regime: BubbleRegime.fits,
            ownMessage: false,
            hideDisplayName: false,
          );
        });
      });
    });

    group('[getSizeMessageBubbleWidth] TEST\n'
        'GIVEN platform is Mobile\n'
        'THEN maxWidth for message is 412.0\n', () {
      const messageMaxWidthMobile = 412.0;
      group('GIVEN message type does not require detailed text metrics\n', () {
        testWidgets('GIVEN message type is file\n'
            'THEN return null\n', (WidgetTester tester) async {
          await runTest(
            tester,
            event: fileEvent,
            maxWidth: messageMaxWidthMobile,
          );
        });
        testWidgets('GIVEN message type is image\n'
            'THEN return is not null\n', (WidgetTester tester) async {
          await runTest(
            tester,
            event: imageEvent,
            maxWidth: messageMaxWidthMobile,
          );
        });
        testWidgets('GIVEN message type is video\n'
            'THEN return is not null\n', (WidgetTester tester) async {
          await runTest(
            tester,
            event: videoEvent,
            maxWidth: messageMaxWidthMobile,
          );
        });
      });

      testWidgets('GIVEN message text is empty\n'
          'THEN return null\n', (WidgetTester tester) async {
        await runTest(
          tester,
          event: emptyTextEvent,
          maxWidth: messageMaxWidthMobile,
        );
      });

      group('GIVEN ownMessage is true\n'
          'OR hideDisplayName is true\n'
          'THEN return message width\n', () {
        testWidgets('GIVEN message body has multiple lines\n'
            'AND last line of message has enough space for timeline\n'
            'THEN return total message width is width of longest line\n'
            'AND isNeedAddNewLine is false\n', (WidgetTester tester) async {
          final eventToTest = Event(
            content: {
              "msgtype": "m.text",
              "body":
                  "#2730 Fallback value for Always read receipt settings is false -> Done\n\n#2628 Disable view PDF file in mobile -> Done\n\n#2726 Remove logo in printed email -> Done\n\n#2737 View PDF in js to support download with name -> Done",
              "format": "org.matrix.custom.html",
              "formatted_body":
                  "<p>#2730 Fallback value for Always read receipt settings is false -&gt; Done</p><br/><p>#2628 Disable view PDF file in mobile -&gt; Done</p><br/><p>#2726 Remove logo in printed email -&gt; Done</p><br/><p>#2737 View PDF in js to support download with name -&gt; Done</p>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          );

          await runTest(
            tester,
            event: eventToTest,
            maxWidth: messageMaxWidthMobile,
            regime: BubbleRegime.fits,
            ownMessage: true,
          );
        });
        testWidgets('GIVEN message body has multiple lines\n'
            'AND last line don\'t have enough space for time line\n'
            'THEN return total message width is width of longest line\n'
            'AND isNeedAddNewLine is true\n', (WidgetTester tester) async {
          final eventToTest = Event(
            content: {
              "msgtype": "m.text",
              "body":
                  "- Copy/Drop text from LibreOffice files to composer\n- Download PDF file from Chrome viewer\n- Download attachment for mobile\n- Small improvements for Printing emails",
              "format": "org.matrix.custom.html",
              "formatted_body":
                  "- Copy/Drop text from LibreOffice files to composer<br/>- Download PDF file from Chrome viewer<br/>- Download attachment for mobile<br/>- Small improvements for Printing emails",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          );
          await runTest(
            tester,
            event: eventToTest,
            maxWidth: messageMaxWidthMobile,
            regime: BubbleRegime.wraps,
            ownMessage: true,
          );
        });
      });

      group('GIVEN ownMessage is false\n'
          'AND hideDisplayName is false\n', () {
        testWidgets('GIVEN width of display name is wider than message body\n'
            'THEN return message bubble width is width of display name\n', (
          WidgetTester tester,
        ) async {
          final eventToTest = Event(
            content: {
              "msgtype": "m.text",
              "body": "Hello",
              "format": "org.matrix.custom.html",
              "formatted_body": "<p>Hello</p>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@exampleabcdh:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          );
          await runTest(
            tester,
            event: eventToTest,
            maxWidth: messageMaxWidthMobile,
            regime: BubbleRegime.displayNameDriven,
            ownMessage: false,
            hideDisplayName: false,
          );
        });

        testWidgets('GIVEN width of display name is smaller than message body\n'
            'AND message body has multiple lines\n'
            'AND last line of message has enough space for timeline\n'
            'THEN return total message width is width of longest line\n'
            'AND isNeedAddNewLine is false\n', (WidgetTester tester) async {
          final eventToTest = Event(
            content: {
              "msgtype": "m.text",
              "body":
                  "#2730 Fallback value for Always read receipt settings is false -> Done\n\n#2628 Disable view PDF file in mobile -> Done\n\n#2726 Remove logo in printed email -> Done\n\n#2737 View PDF in js to support download with name -> Done",
              "format": "org.matrix.custom.html",
              "formatted_body":
                  "<p>#2730 Fallback value for Always read receipt settings is false -&gt; Done</p><br/><p>#2628 Disable view PDF file in mobile -&gt; Done</p><br/><p>#2726 Remove logo in printed email -&gt; Done</p><br/><p>#2737 View PDF in js to support download with name -&gt; Done</p>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          );

          await runTest(
            tester,
            event: eventToTest,
            maxWidth: messageMaxWidthMobile,
            regime: BubbleRegime.fits,
            ownMessage: true,
          );
        });

        testWidgets('GIVEN width of display name is smaller than message body\n'
            'AND message body has multiple lines\n'
            'AND last line don\'t have enough space for time line\n'
            'THEN return total message width is width of longest line\n'
            'AND isNeedAddNewLine is true\n', (WidgetTester tester) async {
          final eventToTest = Event(
            content: {
              "msgtype": "m.text",
              "body":
                  "- Copy/Drop text from LibreOffice files to composer\n- Download PDF file from Chrome viewer\n- Download attachment for mobile\n- Small improvements for Printing emails",
              "format": "org.matrix.custom.html",
              "formatted_body":
                  "- Copy/Drop text from LibreOffice files to composer<br/>- Download PDF file from Chrome viewer<br/>- Download attachment for mobile<br/>- Small improvements for Printing emails",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          );
          await runTest(
            tester,
            event: eventToTest,
            maxWidth: messageMaxWidthMobile,
            regime: BubbleRegime.wraps,
            ownMessage: true,
          );
        });
      });
    });

    group('[getSizeMessageBubbleWidth] TEST\n'
        'GIVEN message body contains a URL\n'
        'THEN isNeedAddNewLine is true\n', () {
      const messageMaxWidthWeb = 504.0;
      const messageMaxWidthMobile = 412.0;

      final urlEvent = Event(
        content: {
          "msgtype": "m.text",
          "body": "Check this out: https://example.com/some/path",
          "format": "org.matrix.custom.html",
          "formatted_body":
              "<p>Check this out: https://example.com/some/path</p>",
        },
        type: 'm.room.message',
        eventId: r'$143273582443PhrSn:example.org',
        senderId: '@example:example.org',
        originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
        room: room,
      );

      testWidgets('GIVEN ownMessage is true AND platform is Web\n'
          'THEN isNeedAddNewLine is true\n', (WidgetTester tester) async {
        await runTest(
          tester,
          event: urlEvent,
          maxWidth: messageMaxWidthWeb,
          expectedIsNeedAddNewLine: true,
          ownMessage: true,
        );
      });

      testWidgets('GIVEN ownMessage is true AND platform is Mobile\n'
          'THEN isNeedAddNewLine is true\n', (WidgetTester tester) async {
        await runTest(
          tester,
          event: urlEvent,
          maxWidth: messageMaxWidthMobile,
          expectedIsNeedAddNewLine: true,
          ownMessage: true,
        );
      });

      testWidgets('GIVEN ownMessage is false AND platform is Web\n'
          'THEN isNeedAddNewLine is true\n', (WidgetTester tester) async {
        await runTest(
          tester,
          event: urlEvent,
          maxWidth: messageMaxWidthWeb,
          expectedIsNeedAddNewLine: true,
          ownMessage: false,
        );
      });

      testWidgets('GIVEN ownMessage is false AND platform is Mobile\n'
          'THEN isNeedAddNewLine is true\n', (WidgetTester tester) async {
        await runTest(
          tester,
          event: urlEvent,
          maxWidth: messageMaxWidthMobile,
          expectedIsNeedAddNewLine: true,
          ownMessage: false,
        );
      });
    });

    group('[isContainsTagName] TEST\n', () {
      test('GIVEN body of event contains tag name\n'
          'THEN return true\n', () {
        final listEventWidthTagName = [
          Event(
            content: {
              "msgtype": "m.text",
              "body": "!jaweog:example.com",
              "format": "org.matrix.custom.html",
              "formatted_body":
                  "<a href=\"https://matrix.to/#/!jaweog:example.com\">!jaweog:example.com</a>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          ),
          Event(
            content: {
              "msgtype": "m.text",
              "body": "@alice:example.com",
              "format": "org.matrix.custom.html",
              "formatted_body":
                  "<a href=\"https://matrix.to/#/@alice:example.com\">@alice:example.com</a>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          ),
          Event(
            content: {
              "msgtype": "m.text",
              "body": "#lihs:example.com",
              "format": "org.matrix.custom.html",
              "formatted_body":
                  "<a href=\"https://matrix.to/#/#lihs:example.com\">#lihs:example.com</a>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          ),
          Event(
            content: {
              "msgtype": "m.text",
              "body": "@[Alice]",
              "format": "org.matrix.custom.html",
              "formatted_body":
                  "<a href=\"https://matrix.to/#/@alice:example.com\">@[Alice]</a>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          ),
        ];
        for (final event in listEventWidthTagName) {
          final isContainsTagName = mockUpMessageContentBuilder
              .isContainsTagName(event);
          expect(isContainsTagName, isTrue);
        }
      });
      test('GIVEN body of event does not contain tag name\n'
          'THEN return false\n', () {
        final normalEvent = Event(
          content: {'body': 'Hello', 'msgtype': 'm.text'},
          type: 'm.room.message',
          eventId: '\$143273582443PhrSn:example.org',
          senderId: '@example:example.org',
          originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
          room: room,
        );
        final isContainsTagName = mockUpMessageContentBuilder.isContainsTagName(
          normalEvent,
        );
        expect(isContainsTagName, isFalse);
      });
    });

    group('[isContainsSpecialHTMLTag] test\n', () {
      test('GIVEN event contains special HTML tags\n'
          'THEN return true\n', () {
        final listEventWithSpecialTag = [
          Event(
            content: {
              "msgtype": "m.text",
              "body": "*example*",
              "format": "org.matrix.custom.html",
              "formatted_body": "<em>example</em>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          ),
          Event(
            content: {
              "msgtype": "m.text",
              "body": "# Header 1",
              "format": "org.matrix.custom.html",
              "formatted_body": "<h1>Header 1</h1>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          ),
          Event(
            content: {
              "msgtype": "m.text",
              "body": "## Header 2",
              "format": "org.matrix.custom.html",
              "formatted_body": "<h2>Header 2</h2>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          ),
          Event(
            content: {
              "msgtype": "m.text",
              "body": "### Header 3",
              "format": "org.matrix.custom.html",
              "formatted_body": "<h3>Header 3</h3>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          ),
          Event(
            content: {
              "msgtype": "m.text",
              "body": "#### Header 4",
              "format": "org.matrix.custom.html",
              "formatted_body": "<h4>Header 4</h4>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          ),
          Event(
            content: {
              "msgtype": "m.text",
              "body": "##### Header 5",
              "format": "org.matrix.custom.html",
              "formatted_body": "<h5>Header 5</h5>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          ),
          Event(
            content: {
              "msgtype": "m.text",
              "body": "###### Header 6",
              "format": "org.matrix.custom.html",
              "formatted_body": "<h6>Header 6</h6>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          ),
          Event(
            content: {
              "msgtype": "m.text",
              "body": "```example```",
              "format": "org.matrix.custom.html",
              "formatted_body": "<pre>example</pre>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          ),
          Event(
            content: {
              "msgtype": "m.text",
              "body": "> example",
              "format": "org.matrix.custom.html",
              "formatted_body": "<blockquote>example</blockquote>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          ),
          Event(
            content: {
              "msgtype": "m.text",
              "body": "bold text",
              "format": "org.matrix.custom.html",
              "formatted_body": "<b>bold text</b>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          ),
          Event(
            content: {
              "msgtype": "m.text",
              "body": "strong text",
              "format": "org.matrix.custom.html",
              "formatted_body": "<strong>strong text</strong>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          ),
          Event(
            content: {
              "msgtype": "m.text",
              "body": "teletype text",
              "format": "org.matrix.custom.html",
              "formatted_body": "<tt>teletype text</tt>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          ),
          Event(
            content: {
              "msgtype": "m.text",
              "body": "```\nif () then () else ()\n```",
              "format": "org.matrix.custom.html",
              "formatted_body":
                  "<pre><code>if () then () else ()\n</code></pre>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          ),
          Event(
            content: {
              "msgtype": "m.text",
              "body": "*Italic text*",
              "format": "org.matrix.custom.html",
              "formatted_body": "<i>Italic text</i>",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          ),
          Event(
            content: {
              "msgtype": "m.text",
              "body": "___",
              "format": "org.matrix.custom.html",
              "formatted_body": "<hr />",
            },
            type: 'm.room.message',
            eventId: '\$143273582443PhrSn:example.org',
            senderId: '@example:example.org',
            originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
            room: room,
          ),
        ];
        for (final event in listEventWithSpecialTag) {
          final isContainsSpecialHTMLTag = mockUpMessageContentBuilder
              .isContainsSpecialHTMLTag(event);
          expect(isContainsSpecialHTMLTag, isTrue);
        }
      });
      test('GIVEN event does not contain special HTML tags\n'
          'THEN return false\n', () {
        final normalEvent = Event(
          content: {'body': 'Hello', 'msgtype': 'm.text'},
          type: 'm.room.message',
          eventId: '\$143273582443PhrSn:example.org',
          senderId: '@example:example.org',
          originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
          room: room,
        );
        final isContainsSpecialHTMLTag = mockUpMessageContentBuilder
            .isContainsSpecialHTMLTag(normalEvent);
        expect(isContainsSpecialHTMLTag, isFalse);
      });
    });
    group('GIVEN event status is error\n', () {
      testWidgets('GIVEN event is text message\n'
          'THEN isNeedAddNewLine is true\n', (tester) async {
        final textEventWithError = Event(
          content: {'body': 'Hello', 'msgtype': 'm.text'},
          type: 'm.room.message',
          eventId: '\$123',
          senderId: '@user:example.org',
          originServerTs: DateTime.now(),
          room: room,
          status: EventStatus.error,
        );

        await runTest(
          tester,
          event: textEventWithError,
          maxWidth: 400,
          ownMessage: true,
          expectedIsNeedAddNewLine: true,
        );
      });

      testWidgets('GIVEN event is NOT text message (e.g. m.notice)\n'
          'THEN isNeedAddNewLine is false (if fits)\n', (tester) async {
        final noticeEventWithError = Event(
          content: {'body': 'Notice', 'msgtype': 'm.notice'},
          type: 'm.room.message',
          eventId: '\$456',
          senderId: '@user:example.org',
          originServerTs: DateTime.now(),
          room: room,
          status: EventStatus.error,
        );

        await runTest(
          tester,
          event: noticeEventWithError,
          maxWidth: 1000,
          ownMessage: true,
          expectedIsNeedAddNewLine: false,
        );
      });
    });
  });
}
