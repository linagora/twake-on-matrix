import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart' as provider;
import 'package:pull_down_button/pull_down_button.dart';
import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/events/html_message.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/twake_components/twake_preview_link/twake_link_preview.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../fake_client.dart';

class _FakeMatrixState extends Fake implements MatrixState {
  _FakeMatrixState(this.client);

  @override
  final Client client;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  final launches = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launches.add(url);
    return true;
  }
}

const _url = 'https://example.com/a-long-link-to-press';
const _phone = '+33 6 12 34 56 78';

void main() {
  late Room room;
  late _FakeUrlLauncherPlatform platform;

  setUpAll(() async {
    room = Room(id: '!room:example.org', client: await getClient());
  });

  setUp(() {
    platform = _FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = platform;
  });

  // The pull-down phone menu is the mobile one.
  void onIOS() {
    PlatformInfos.isTestingForIOS = true;
    addTearDown(() => PlatformInfos.isTestingForIOS = false);
  }

  Event textEvent(String body) => Event(
    content: {'body': body, 'msgtype': 'm.text'},
    type: 'm.room.message',
    eventId: '\$event:example.org',
    senderId: '@example:example.org',
    originServerTs: DateTime.fromMillisecondsSinceEpoch(1894270481925),
    room: room,
  );

  final messages = <String, Widget Function(String)>{
    'HtmlMessage': (body) => HtmlMessage(
      html: '<p>$body</p>',
      room: room,
      linkStyle: const TextStyle(color: Colors.blue),
    ),
    'TwakeLinkPreview': (body) => TwakeLinkPreview(
      event: textEvent(body),
      localizedBody: body,
      ownMessage: false,
      fontSize: 14,
    ),
  };

  Future<ScrollController> pumpInTimeline(
    WidgetTester tester,
    Widget message, {
    VoidCallback? onLongPress,
  }) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: provider.Provider<MatrixState>.value(
          value: _FakeMatrixState(room.client),
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: const [
              L10n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: LocalizationService.supportedLocales,
            home: Scaffold(
              body: ListView(
                controller: scrollController,
                children: [
                  const SizedBox(height: 200),
                  GestureDetector(onLongPress: onLongPress, child: message),
                  const SizedBox(height: 2000),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return scrollController;
  }

  Offset linkStart(WidgetTester tester, String text) {
    final rect = tester.getRect(
      find.textContaining(text, findRichText: true).first,
    );
    return Offset(rect.left + 20, rect.center.dy);
  }

  Future<void> pressHoldThenDrag(WidgetTester tester, Offset start) async {
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 300));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, -30));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  Future<void> activateWithScreenReader(
    WidgetTester tester,
    String label,
  ) async {
    tester.semantics.tap(find.semantics.byLabel(label));
    await tester.pumpAndSettle();
  }

  for (final MapEntry(key: name, value: build) in messages.entries) {
    group('$name links', () {
      testWidgets('a drag that starts on a link scrolls without opening it', (
        tester,
      ) async {
        final scrollController = await pumpInTimeline(tester, build(_url));

        await pressHoldThenDrag(tester, linkStart(tester, _url));

        expect(platform.launches, isEmpty);
        expect(scrollController.offset, greaterThan(0));
      });

      testWidgets('a tap on a link opens it', (tester) async {
        await pumpInTimeline(tester, build(_url));

        await tester.tapAt(linkStart(tester, _url));
        await tester.pumpAndSettle();

        expect(platform.launches, [_url]);
      });

      testWidgets('a drag that starts on a phone number opens no menu', (
        tester,
      ) async {
        onIOS();
        await pumpInTimeline(tester, build(_phone));

        await pressHoldThenDrag(tester, linkStart(tester, _phone));

        expect(find.byType(PullDownMenuItem), findsNothing);
      });

      testWidgets('a tap on a phone number opens its menu at the tap', (
        tester,
      ) async {
        onIOS();
        await pumpInTimeline(tester, build(_phone));
        final tap = linkStart(tester, _phone);

        await tester.tapAt(tap);
        await tester.pumpAndSettle();

        final copy = find.text('Copy number');
        expect(copy, findsOneWidget);
        expect(tester.getRect(copy).top, greaterThan(tap.dy));
        expect(tester.getRect(copy).top, lessThan(tap.dy + 150));
      });

      testWidgets('a long press on a link goes to the message', (tester) async {
        var longPressed = false;
        await pumpInTimeline(
          tester,
          build(_url),
          onLongPress: () => longPressed = true,
        );

        await tester.longPressAt(linkStart(tester, _url));
        await tester.pumpAndSettle();

        expect(longPressed, isTrue);
        expect(platform.launches, isEmpty);
      });

      testWidgets(
        'a screen-reader activation of a phone number opens its menu at the '
        'message',
        (tester) async {
          onIOS();
          await pumpInTimeline(tester, build(_phone));
          final message = tester.getRect(
            find.byWidgetPredicate((w) => w.runtimeType.toString() == name),
          );

          await activateWithScreenReader(tester, _phone);

          final copy = find.text('Copy number');
          expect(copy, findsOneWidget);
          expect(tester.getRect(copy).top, greaterThan(message.top));
          expect(tester.getRect(copy).top, lessThan(message.bottom + 150));
        },
      );

      testWidgets(
        'a screen-reader activation after a tap ignores the old tap position',
        (tester) async {
          onIOS();
          final scrollController = await pumpInTimeline(tester, build(_phone));
          final tap = linkStart(tester, _phone);
          await tester.tapAt(tap);
          await tester.pumpAndSettle();
          Navigator.of(tester.element(find.text('Copy number'))).pop();
          await tester.pumpAndSettle();
          scrollController.jumpTo(150);
          await tester.pumpAndSettle();

          await activateWithScreenReader(tester, _phone);

          expect(
            tester.getRect(find.text('Copy number')).top,
            lessThan(tap.dy - 50),
          );
        },
      );
    });
  }

  group('HtmlMessage anchors', () {
    const label = 'Read the release notes';
    Widget anchor() => HtmlMessage(
      html: '<p><a href="$_url">$label</a></p>',
      room: room,
      linkStyle: const TextStyle(color: Colors.blue),
    );

    testWidgets('a drag that starts on an anchor scrolls without opening it', (
      tester,
    ) async {
      final scrollController = await pumpInTimeline(tester, anchor());

      await pressHoldThenDrag(tester, linkStart(tester, label));

      expect(platform.launches, isEmpty);
      expect(scrollController.offset, greaterThan(0));
    });

    testWidgets('a tap on an anchor opens its href', (tester) async {
      await pumpInTimeline(tester, anchor());

      await tester.tapAt(linkStart(tester, label));
      await tester.pumpAndSettle();

      expect(platform.launches, [_url]);
    });
  });
}
