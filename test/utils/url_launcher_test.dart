import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/utils/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  final launches = <(String, PreferredLaunchMode)>[];
  bool launchResult = true;
  Object? launchError;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launches.add((url, options.mode));
    if (launchError != null) throw launchError!;
    return launchResult;
  }
}

void main() {
  late _FakeUrlLauncherPlatform platform;
  late BuildContext context;

  setUpAll(() {
    GetIt.instance.registerSingleton(ResponsiveUtils());
  });

  tearDownAll(() {
    GetIt.instance.reset();
  });

  setUp(() {
    platform = _FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = platform;
  });

  Future<void> launch(WidgetTester tester, String url) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: LocalizationService.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    UrlLauncher(context, url: url).launchUrl();
    await tester.pump();
  }

  Finder cantOpen(String url) => find.text("Can't open the URI $url");

  group('GIVEN a link with a custom app scheme\n', () {
    for (final url in [
      'visio://toto',
      'visio://meet.example.com/room?x=1',
      'maps://?q=Paris',
      'mailto:someone@example.com',
      'tel:+33123456789',
      'sms:+33123456789',
    ]) {
      testWidgets('WHEN $url is tapped\n'
          'THEN it is launched as-is in an external app', (tester) async {
        await launch(tester, url);

        expect(platform.launches, [
          (url, PreferredLaunchMode.externalApplication),
        ]);
        expect(cantOpen(url), findsNothing);
      });
    }

    testWidgets('WHEN no app can open it\n'
        'THEN a "can\'t open" message is shown', (tester) async {
      platform.launchResult = false;

      await launch(tester, 'visio://toto');

      expect(platform.launches, hasLength(1));
      expect(cantOpen('visio://toto'), findsOneWidget);
    });

    testWidgets('WHEN the platform throws\n'
        'THEN a "can\'t open" message is shown', (tester) async {
      platform.launchError = PlatformException(code: 'ACTIVITY_NOT_FOUND');

      await launch(tester, 'visio://toto');

      expect(platform.launches, hasLength(1));
      expect(cantOpen('visio://toto'), findsOneWidget);
    });
  });

  group('GIVEN a link with a blocked scheme\n', () {
    for (final url in [
      'file:///etc/passwd',
      'javascript:alert(1)',
      'data:text/html,<script>alert(1)</script>',
    ]) {
      testWidgets('WHEN $url is tapped\n'
          'THEN nothing is launched and a message is shown', (tester) async {
        await launch(tester, url);

        expect(platform.launches, isEmpty);
        expect(cantOpen(url), findsOneWidget);
      });
    }
  });

  group('GIVEN a link without scheme\n', () {
    for (final (url, expected) in [
      ('example.com', 'https://example.com'),
      ('www.example.com/path?q=1', 'https://www.example.com/path?q=1'),
      ('example.com:8080/path', 'https://example.com:8080/path'),
      ('localhost:8080', 'https://localhost:8080'),
    ]) {
      testWidgets('WHEN $url is tapped\n'
          'THEN it is opened over https', (tester) async {
        await launch(tester, url);

        expect(platform.launches.single.$1, expected);
        expect(cantOpen(url), findsNothing);
      });
    }
  });

  group('GIVEN an http(s) link\n', () {
    for (final (url, expected) in [
      ('https://example.com/a?b=c#d', 'https://example.com/a?b=c#d'),
      ('http://example.com', 'http://example.com'),
      ('https://bücher.de', 'https://xn--bcher-kva.de'),
    ]) {
      testWidgets('WHEN $url is tapped\n'
          'THEN it is opened in an external app', (tester) async {
        await launch(tester, url);

        expect(platform.launches, [
          (expected, PreferredLaunchMode.externalApplication),
        ]);
      });
    }
  });

  group('GIVEN a geo link on desktop\n', () {
    testWidgets('WHEN it is tapped\n'
        'THEN it is opened on OpenStreetMap', (tester) async {
      await launch(tester, 'geo:48.85,2.35');

      expect(
        platform.launches.single.$1,
        'https://www.openstreetmap.org/?mlat=48.85&mlon=2.35#map=16/48.85/2.35',
      );
    });
  });
}
