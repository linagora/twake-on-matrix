import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/data/repository/public_rooms/public_rooms_repository.provider.dart';
import 'package:twake_chat/domain/message_link/policy/message_link_policy.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room_preview.dart';
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
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../domain/public_rooms/fake_public_rooms_repository.dart';

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
    // The app runs under a ProviderScope; UrlLauncher reads the active
    // client from it.
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
    const invitedRoomId = '!invited:example.org';
    const eventId = r'$event';
    late _FakeClient client;
    late FakePublicRoomsRepository publicRooms;

    setUp(() {
      publicRooms = FakePublicRoomsRepository()
        ..preview = const PublicRoomPreview.found(
          PublicRoom(
            roomId: '!general:example.org',
            name: 'General',
            memberCount: 3,
            access: PublicRoomAccess.open,
            kind: PublicRoomKind.group,
          ),
        );
      client = _FakeClient();
      client.joined[roomId] = Room(
        id: roomId,
        client: client,
        membership: Membership.join,
      );
      client.joined[invitedRoomId] = Room(
        id: invitedRoomId,
        client: client,
        membership: Membership.invite,
      );
    });

    Future<void> launchInApp(WidgetTester tester, String url) async {
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
          retry: (_, _) => null,
          overrides: [
            activeMatrixClientProvider.overrideWithValue(client),
            publicRoomsRepositoryProvider.overrideWithValue(publicRooms),
          ],
          child: provider.Provider<MatrixState>.value(
            value: _FakeMatrixState(client),
            child: MaterialApp.router(
              routerConfig: router,
              locale: const Locale('en'),
              localizationsDelegates: const [
                L10n.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              supportedLocales: LocalizationService.supportedLocales,
            ),
          ),
        ),
      );
      UrlLauncher(context, url: url).launchUrl();
      await tester.pumpAndSettle();
    }

    for (final id in [roomId, invitedRoomId]) {
      testWidgets('WHEN the user is in $id or invited to it\n'
          'THEN it opens in the app at the event', (tester) async {
        await launchInApp(tester, '$webUrl/rooms/$id?event=$eventId');

        expect(find.text('room $id event $eventId'), findsOneWidget);
        expect(platform.launches, isEmpty);
      });
    }

    testWidgets('WHEN the user is not in the room\n'
        'THEN its preview is shown in the app, never the browser', (
      tester,
    ) async {
      await launchInApp(
        tester,
        '$webUrl/rooms/!unknown%3Aexample.org?event=$eventId',
      );

      expect(platform.launches, isEmpty);
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Join · 3 members'), findsOneWidget);
      expect(publicRooms.previewQueries, ['!unknown:example.org']);
    });

    testWidgets('WHEN it is the share link of a room, on its alias\n'
        'THEN its preview is shown in the app, never the browser', (
      tester,
    ) async {
      await launchInApp(tester, '$webUrl/rooms/%23general%3Aexample.org');

      expect(platform.launches, isEmpty);
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Join · 3 members'), findsOneWidget);
      expect(publicRooms.previewQueries, ['#general:example.org']);
    });

    testWidgets('WHEN the link names via servers\n'
        'THEN the room is looked up through them', (tester) async {
      await launchInApp(
        tester,
        '$webUrl/rooms/!opaque?via=example.org&via=other.org',
      );

      expect(platform.launches, isEmpty);
      expect(find.text('General'), findsOneWidget);
      expect(publicRooms.previewQueries, ['!opaque']);
      expect(publicRooms.previewVia.single, ['example.org', 'other.org']);
    });

    testWidgets('WHEN the room cannot be previewed\n'
        'THEN the sheet offers to open the original link in the browser', (
      tester,
    ) async {
      const link = 'https://other.example.com/rooms/!opaque?event=%24event';
      publicRooms.preview = const PublicRoomPreview.unavailable();
      await launchInApp(tester, link);
      expect(find.text('This group is unavailable.'), findsOneWidget);
      expect(platform.launches, isEmpty);

      await tester.tap(find.text('Open in browser'));
      await tester.pumpAndSettle();

      expect(platform.launches, [
        (link, PreferredLaunchMode.externalApplication),
      ]);
      expect(find.text('This group is unavailable.'), findsNothing);
    });

    testWidgets('WHEN a matrix.to link names a room that cannot be previewed\n'
        'THEN the sheet has no browser button', (tester) async {
      publicRooms.preview = const PublicRoomPreview.unavailable();

      await launchInApp(tester, 'https://matrix.to/#/%23general%3Aexample.org');

      expect(find.text('This group is unavailable.'), findsOneWidget);
      expect(find.text('Open in browser'), findsNothing);
    });

    testWidgets('WHEN the user opens the link copied from a message\n'
        'THEN it opens the room at that message', (tester) async {
      final copied = const MessageLinkPolicy().build(
        roomId: roomId,
        eventId: eventId,
        userId: '@me:other.org',
      );

      await launchInApp(tester, copied);

      expect(find.text('room $roomId event $eventId'), findsOneWidget);
      expect(platform.launches, isEmpty);
    });

    // The Matrix SDK reads an identifier of 255 characters at most; the
    // server part below is 12 characters once decoded.
    const server = '%3Aexample.org';
    final roomOf255 = '!${'a' * 242}$server';
    final eventOf255 = '%24${'a' * 254}';

    for (final (label, link) in [
      // The policy rejects it.
      (
        'an ?event= that is no event id',
        '$webUrl/rooms/!abc$server?event=notanevent',
      ),
      // The SDK cannot read it: one character over the longest identifier.
      ('a room id of 256 characters', '$webUrl/rooms/!${'a' * 243}$server'),
      ('an alias of 256 characters', '$webUrl/rooms/%23${'a' * 243}$server'),
      (
        'an event id of 256 characters',
        '$webUrl/rooms/!abc$server?event=${eventOf255}a',
      ),
    ]) {
      testWidgets('WHEN the link has $label\n'
          'THEN it opens in the browser', (tester) async {
        await launchInApp(tester, link);

        expect(platform.launches, [
          (link, PreferredLaunchMode.externalApplication),
        ]);
        expect(find.text('Join · 3 members'), findsNothing);
      });
    }

    for (final (label, link, address) in [
      (
        'a room id of 255 characters',
        '$webUrl/rooms/$roomOf255',
        Uri.decodeComponent(roomOf255),
      ),
      (
        'an event id of 255 characters',
        '$webUrl/rooms/!abc$server?event=$eventOf255',
        '!abc:example.org',
      ),
    ]) {
      testWidgets('WHEN the link has $label\n'
          'THEN it still opens in the app', (tester) async {
        await launchInApp(tester, link);

        expect(platform.launches, isEmpty);
        expect(find.text('Join · 3 members'), findsOneWidget);
        expect(publicRooms.previewQueries, [address]);
      });
    }
  });
}
