// ignore_for_file: depend_on_referenced_packages

import 'package:fluffychat/config/localizations/localization_service.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/domain/model/user_info/user_info.dart';
import 'package:fluffychat/presentation/mixins/message_avatar_mixin.dart';
import 'package:fluffychat/utils/manager/twake_user_info_manager/twake_user_info_manager.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/theme_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'message_avatar_mixin_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<User>(),
  MockSpec<Room>(),
  MockSpec<TwakeUserInfoManager>(),
])
class MockMessageAvatarUtils with MessageAvatarMixin {}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockMessageAvatarUtils mockMessageAvatarUtils;
  late MockTwakeUserInfoManager mockTwakeUserInfoManager;
  late Event event;
  setUpAll(() {
    final getIt = GetIt.instance;
    getIt.registerSingleton(ResponsiveUtils());
    mockTwakeUserInfoManager = MockTwakeUserInfoManager();
    getIt.registerSingleton<TwakeUserInfoManager>(mockTwakeUserInfoManager);
    mockMessageAvatarUtils = MockMessageAvatarUtils();
  });

  group('Tests for when the avatar next to a message should be displayed ', () {
    setUp(() {
      final room = MockRoom();
      event = Event(
        content: {
          'body': 'Test message',
          'msgtype': 'm.text',
        },
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
      required bool ownMessage,
      required Size screenSize,
      required bool isDirectChat,
    }) async {
      when(event.room.isDirectChat).thenReturn(isDirectChat);

      // Stub TwakeUserInfoManager to return test user info
      when(
        mockTwakeUserInfoManager.getTwakeProfileFromUserId(
          client: anyNamed('client'),
          userId: event.senderId,
        ),
      ).thenAnswer(
        (_) async => const UserInfo(
          uid: '@bob:example.com',
          displayName: 'Test',
          avatarUrl: 'fakeImage',
        ),
      );

      Widget? widget;
      await tester.pumpWidget(
        ThemeBuilder(
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
              data: MediaQueryData(
                size: screenSize,
              ),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  widget = mockMessageAvatarUtils.placeHolderWidget(
                    (_) {},
                    sameSender: sameSender,
                    ownMessage: ownMessage,
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
      );

      await tester.pumpAndSettle();
    }

    group('Web-sized screens', () {
      const webSize = Size(1200, 800);

      testWidgets(
        'Should display Avatar when Own message in group chat',
        (WidgetTester tester) async {
          await runTest(
            tester,
            event: event,
            selectMode: false,
            sameSender: true,
            ownMessage: true,
            screenSize: webSize,
            isDirectChat: false,
          );
          verify(
            mockTwakeUserInfoManager.getTwakeProfileFromUserId(
              client: anyNamed('client'),
              userId: event.senderId,
            ),
          ).called(1);
          expect(find.byType(Avatar), findsOneWidget);
        },
      );

      testWidgets(
        'Should display Avatar when Own message in direct chat',
        (WidgetTester tester) async {
          await runTest(
            tester,
            event: event,
            selectMode: false,
            sameSender: true,
            ownMessage: true,
            screenSize: webSize,
            isDirectChat: true,
          );
          verify(
            mockTwakeUserInfoManager.getTwakeProfileFromUserId(
              client: anyNamed('client'),
              userId: event.senderId,
            ),
          ).called(1);
          expect(find.byType(Avatar), findsOneWidget);
        },
      );

      testWidgets(
        'Should return Avatar when Not my message in direct chat',
        (WidgetTester tester) async {
          await runTest(
            tester,
            event: event,
            selectMode: false,
            sameSender: true,
            ownMessage: false,
            screenSize: webSize,
            isDirectChat: true,
          );
          verify(
            mockTwakeUserInfoManager.getTwakeProfileFromUserId(
              client: anyNamed('client'),
              userId: event.senderId,
            ),
          ).called(1);
          expect(find.byType(Avatar), findsOneWidget);
        },
      );

      testWidgets(
        'Should return Avatar when not my message in group chat',
        (WidgetTester tester) async {
          await runTest(
            tester,
            event: event,
            selectMode: false,
            sameSender: true,
            ownMessage: false,
            screenSize: webSize,
            isDirectChat: false,
          );
          verify(
            mockTwakeUserInfoManager.getTwakeProfileFromUserId(
              client: anyNamed('client'),
              userId: event.senderId,
            ),
          ).called(1);
          expect(find.byType(Avatar), findsOneWidget);
        },
      );

      testWidgets(
        'Should return SizedBox when Select mode is active',
        (WidgetTester tester) async {
          await runTest(
            tester,
            event: event,
            selectMode: true,
            sameSender: true,
            ownMessage: false,
            screenSize: webSize,
            isDirectChat: true,
          );
          verifyNever(
            mockTwakeUserInfoManager.getTwakeProfileFromUserId(
              client: anyNamed('client'),
              userId: event.senderId,
            ),
          );
          expect(find.byType(SizedBox), findsOneWidget);
        },
      );
    });
    group('Mobile-sized screens', () {
      const mobileSize = Size(400, 800);

      testWidgets(
        'Should return SizedBox when Own message in group chat',
        (WidgetTester tester) async {
          await runTest(
            tester,
            event: event,
            selectMode: false,
            sameSender: true,
            ownMessage: true,
            isDirectChat: false,
            screenSize: mobileSize,
          );
          verifyNever(
            mockTwakeUserInfoManager.getTwakeProfileFromUserId(
              client: anyNamed('client'),
              userId: event.senderId,
            ),
          );
          expect(find.byType(SizedBox), findsOneWidget);
        },
      );

      testWidgets(
        'Should return SizedBox when Own message in direct chat',
        (WidgetTester tester) async {
          await runTest(
            tester,
            event: event,
            selectMode: false,
            sameSender: true,
            ownMessage: true,
            screenSize: mobileSize,
            isDirectChat: true,
          );
          verifyNever(
            mockTwakeUserInfoManager.getTwakeProfileFromUserId(
              client: anyNamed('client'),
              userId: event.senderId,
            ),
          );
          expect(find.byType(SizedBox), findsOneWidget);
        },
      );

      testWidgets(
        'Should return SizedBox when Not my message in direct chat',
        (WidgetTester tester) async {
          await runTest(
            tester,
            event: event,
            selectMode: false,
            sameSender: true,
            ownMessage: false,
            screenSize: mobileSize,
            isDirectChat: true,
          );
          verifyNever(
            mockTwakeUserInfoManager.getTwakeProfileFromUserId(
              client: anyNamed('client'),
              userId: event.senderId,
            ),
          );
          expect(find.byType(SizedBox), findsOneWidget);
        },
      );

      testWidgets(
        'Should return Avatar when Not my message in group chat',
        (WidgetTester tester) async {
          await runTest(
            tester,
            event: event,
            selectMode: false,
            sameSender: true,
            ownMessage: false,
            screenSize: mobileSize,
            isDirectChat: false,
          );
          verify(
            mockTwakeUserInfoManager.getTwakeProfileFromUserId(
              client: anyNamed('client'),
              userId: event.senderId,
            ),
          ).called(1);
          expect(find.byType(Avatar), findsOneWidget);
        },
      );

      testWidgets(
        'Should return SizedBox when Select mode is active',
        (WidgetTester tester) async {
          await runTest(
            tester,
            event: event,
            selectMode: true,
            sameSender: true,
            ownMessage: false,
            screenSize: mobileSize,
            isDirectChat: true,
          );
          verifyNever(
            mockTwakeUserInfoManager.getTwakeProfileFromUserId(
              client: anyNamed('client'),
              userId: event.senderId,
            ),
          );
          expect(find.byType(SizedBox), findsOneWidget);
        },
      );
    });
  });
}
