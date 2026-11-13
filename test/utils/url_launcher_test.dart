import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/utils/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart' as provider;
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _FakeClient extends Fake implements Client {
  final joined = <String, Room>{};

  @override
  Room? getRoomById(String id) => joined[id];

  @override
  Room? getRoomByAlias(String alias) => null;
}

class _FakeMatrixState extends Fake implements MatrixState {
  _FakeMatrixState(this.client);

  @override
  final Client client;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

HomeserverSummary _summaryWithWebUrl(String webUrl) => HomeserverSummary(
  discoveryInformation: DiscoveryInformation(
    additionalProperties: {
      'app.twake.chat': {'web_url': webUrl},
    },
    mHomeserver: HomeserverInformation(
      baseUrl: Uri.parse('https://matrix.example.org'),
    ),
  ),
  versions: GetVersionsResponse(versions: []),
  loginFlows: [],
);

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
    // The app runs under a ProviderScope; UrlLauncher reads the web app
    // origin from it.
    await tester.pumpWidget(
      ProviderScope(
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
            body: Builder(
              builder: (ctx) {
                context = ctx;
                return const SizedBox.shrink();
              },
            ),
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
      'tel:0612345678',
      'sms:+33123456789',
      'skype:echo123?call',
      'sip:alice@example.com',
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

  group('GIVEN a link with the app\'s own scheme\n', () {
    for (final url in ['twake.chat://redirect', 'twake.chat://login']) {
      testWidgets('WHEN $url is tapped\n'
          'THEN nothing is launched and a message is shown', (tester) async {
        await launch(tester, url);

        expect(platform.launches, isEmpty);
        expect(cantOpen(url), findsOneWidget);
      });
    }
  });

  group('GIVEN a link that would open a local file\n', () {
    for (final url in ['file:///etc/passwd', 'FILE:///C:/Windows/calc.exe']) {
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
      ('//example.com/page', 'https://example.com/page'),
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

  group('GIVEN a link to a room of the web app\n', () {
    const webUrl = 'https://chat.example.org';
    const roomId = '!joined:example.org';
    const eventId = r'$event';
    const link = '$webUrl/rooms/$roomId?event=$eventId';
    late _FakeClient client;

    setUp(() {
      client = _FakeClient();
      client.joined[roomId] = Room(
        id: roomId,
        client: client,
        membership: Membership.join,
      );
    });

    Future<void> launchInApp(
      WidgetTester tester,
      String url, {
      String? homeserverWebUrl,
    }) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Builder(
              builder: (ctx) {
                context = ctx;
                return const SizedBox.shrink();
              },
            ),
          ),
          GoRoute(
            path: '/rooms/:roomid',
            builder: (_, state) => Text(
              'room ${state.pathParameters['roomid']} '
              'event ${state.uri.queryParameters['event']}',
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeMatrixClientProvider.overrideWithValue(client),
            loginHomeserverSummaryProvider.overrideWithBuild(
              (_, _) => homeserverWebUrl == null
                  ? null
                  : _summaryWithWebUrl(homeserverWebUrl),
            ),
          ],
          child: provider.Provider<MatrixState>.value(
            value: _FakeMatrixState(client),
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      UrlLauncher(context, url: url).launchUrl();
      await tester.pumpAndSettle();
    }

    testWidgets('WHEN the homeserver names that web app\n'
        'THEN the room opens in the app at the event', (tester) async {
      await launchInApp(tester, link, homeserverWebUrl: webUrl);

      expect(find.text('room $roomId event $eventId'), findsOneWidget);
      expect(platform.launches, isEmpty);
    });

    testWidgets('WHEN the homeserver does not name it and the room is joined\n'
        'THEN the room still opens in the app', (tester) async {
      await launchInApp(tester, link);

      expect(find.text('room $roomId event $eventId'), findsOneWidget);
      expect(platform.launches, isEmpty);
    });

    testWidgets('WHEN the room is unknown and the host is not the web app\n'
        'THEN it is opened in an external app', (tester) async {
      const other = 'https://other.example.com/rooms/!unknown:example.com';

      await launchInApp(tester, other);

      expect(platform.launches, [
        (other, PreferredLaunchMode.externalApplication),
      ]);
    });
  });
}
