// ignore_for_file: depend_on_referenced_packages

import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/presentation/mixins/message_avatar_mixin.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';
import 'package:twake_chat/widgets/theme_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/presence/entities/person_presence.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/providers/person_presence_provider.dart';
import 'package:twake_chat/widgets/avatar/person_presence_badge.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'message_avatar_mixin_test.mocks.dart';

@GenerateNiceMocks([MockSpec<User>(), MockSpec<Room>(), MockSpec<Client>()])
class MockMessageAvatarUtils with MessageAvatarMixin {}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockMessageAvatarUtils mockMessageAvatarUtils;
  late Room room;
  late User user;
  late Event event;
  setUpAll(() {
    final getIt = GetIt.instance;
    getIt.registerSingleton(ResponsiveUtils());
    mockMessageAvatarUtils = MockMessageAvatarUtils();
  });

  group('Tests for when the avatar next to a message should be displayed ', () {
    setUp(() {
      room = MockRoom();
      user = MockUser();
      event = Event(
        content: {'body': 'Test message', 'msgtype': 'm.text'},
        type: 'm.room.message',
        eventId: '7365636s6r64300:example.com',
        senderId: '@bob:example.com',
        originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
        room: room,
      );
    });
    Future<void> runTest(
      WidgetTester tester, {
      required Event event,
      required bool selectMode,
      required bool sameSender,
      required Size screenSize,
      required bool isDirectChat,
      bool ownMessage = false,
    }) async {
      final client = MockClient();
      when(room.client).thenReturn(client);
      when(
        client.userID,
      ).thenReturn(ownMessage ? event.senderId : '@me:example.com');
      when(
        room.requestUser(event.senderId, ignoreErrors: true),
      ).thenAnswer((_) async => user);
      when(
        room.unsafeGetUserFromMemoryOrFallback(event.senderId),
      ).thenReturn(user);
      when(user.avatarUrl).thenReturn(Uri.tryParse("fakeImage"));
      when(user.calcDisplayname()).thenReturn('Test');
      when(event.room.isDirectChat).thenReturn(isDirectChat);
      Widget? widget;
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            syncedPersonPresenceProvider(event.senderId).overrideWith(
              (ref) => Stream.value(
                const PersonPresence(status: PresenceStatus.online),
              ),
            ),
          ],
          child: ThemeBuilder(
            builder: (context, themeMode, primaryColor) => MaterialApp(
              locale: const Locale('en'),
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
                data: MediaQueryData(size: screenSize),
                child: child!,
              ),
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    widget = mockMessageAvatarUtils.placeHolderWidget(
                      (_) {},
                      sameSender: sameSender,
                      event: event,
                      context: context,
                      selectMode: selectMode,
                    );
                    return widget!;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
    }

    testWidgets(
      'Should show the sender presence when not my message in group chat',
      (tester) async {
        await runTest(
          tester,
          event: event,
          selectMode: false,
          sameSender: true,
          screenSize: const Size(400, 800),
          isDirectChat: false,
        );

        final badge = tester.widget<PersonPresenceBadge>(
          find.byType(PersonPresenceBadge),
        );
        expect(badge.userId, '@bob:example.com');
        expect(find.byKey(const ValueKey('linagora-presence-dot')), findsOne);
      },
    );

    testWidgets('Should show no presence when Own message in group chat', (
      tester,
    ) async {
      await runTest(
        tester,
        event: event,
        selectMode: false,
        sameSender: true,
        ownMessage: true,
        screenSize: const Size(1200, 800),
        isDirectChat: false,
      );

      expect(find.byType(Avatar), findsOneWidget);
      expect(find.byType(PersonPresenceBadge), findsNothing);
    });

    testWidgets('Should show no presence when not my message in direct chat', (
      tester,
    ) async {
      await runTest(
        tester,
        event: event,
        selectMode: false,
        sameSender: true,
        screenSize: const Size(400, 800),
        isDirectChat: true,
      );

      expect(find.byType(PersonPresenceBadge), findsNothing);
    });

    group('Web-sized screens', () {
      const webSize = Size(1200, 800);

      testWidgets('Should return SizedBox in direct chat', (
        WidgetTester tester,
      ) async {
        await runTest(
          tester,
          event: event,
          selectMode: false,
          sameSender: true,
          screenSize: webSize,
          isDirectChat: true,
        );
        verifyNever(room.requestUser(event.senderId, ignoreErrors: true));
        expect(find.byType(SizedBox), findsOneWidget);
      });

      testWidgets('Should display Avatar in group chat', (
        WidgetTester tester,
      ) async {
        await runTest(
          tester,
          event: event,
          selectMode: false,
          sameSender: true,
          screenSize: webSize,
          isDirectChat: false,
        );
        verify(room.requestUser(event.senderId, ignoreErrors: true)).called(1);
        expect(find.byType(Avatar), findsOneWidget);
      });

      testWidgets('Should return SizedBox when Select mode is active', (
        WidgetTester tester,
      ) async {
        await runTest(
          tester,
          event: event,
          selectMode: true,
          sameSender: true,
          screenSize: webSize,
          isDirectChat: true,
        );
        verifyNever(room.requestUser(event.senderId, ignoreErrors: true));
        expect(find.byType(SizedBox), findsOneWidget);
      });
    });
    group('Mobile-sized screens', () {
      const mobileSize = Size(400, 800);

      testWidgets('Should return SizedBox in direct chat', (
        WidgetTester tester,
      ) async {
        await runTest(
          tester,
          event: event,
          selectMode: false,
          sameSender: true,
          screenSize: mobileSize,
          isDirectChat: true,
        );
        verifyNever(room.requestUser(event.senderId, ignoreErrors: true));
        expect(find.byType(SizedBox), findsOneWidget);
      });

      // The placeholder is drawn only beside a message on the left: on a
      // phone, an own message is there with « every message on the left »
      // alone, and it then shows my avatar like the others' (review of
      // #3841). The sender does not change the placeholder.
      testWidgets('Should display Avatar in group chat', (
        WidgetTester tester,
      ) async {
        await runTest(
          tester,
          event: event,
          selectMode: false,
          sameSender: true,
          screenSize: mobileSize,
          isDirectChat: false,
        );
        verify(room.requestUser(event.senderId, ignoreErrors: true)).called(1);
        expect(find.byType(Avatar), findsOneWidget);
      });

      testWidgets('Should return SizedBox when Select mode is active', (
        WidgetTester tester,
      ) async {
        await runTest(
          tester,
          event: event,
          selectMode: true,
          sameSender: true,
          screenSize: mobileSize,
          isDirectChat: true,
        );
        verifyNever(room.requestUser(event.senderId, ignoreErrors: true));
        expect(find.byType(SizedBox), findsOneWidget);
      });
    });
  });
}
