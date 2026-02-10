import 'package:fluffychat/config/localizations/localization_service.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/chat_list/chat_custom_slidable_action.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/utils/custom_scroll_behaviour.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/theme_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

import 'chat_list_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Room>()])
void main() {
  const double iconSize = 24.0;
  late final Room room;
  setUpAll(() {
    final getIt = GetIt.instance;
    getIt.registerSingleton(ResponsiveUtils());
    room = MockRoom();
  });

  Future<List<Widget>> makeTestable(WidgetTester tester) async {
    late List<Widget> slideActions;
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
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final controller = ChatListController();
                slideActions = controller.getSlidables(context, room);
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    return slideActions;
  }

  group('[ChatList] TEST', () {
    group('[getSlidables] TEST', () {
      group('GIVEN room is invitation', () {
        testWidgets('GIVEN room is muted\n'
            'THEN return unmute action ', (WidgetTester tester) async {
          when(room.membership).thenReturn(Membership.invite);
          when(room.pushRuleState).thenReturn(PushRuleState.dontNotify);

          final List<Widget> slideActions = await makeTestable(tester);

          expect(slideActions, isNotNull);
          expect(slideActions.length, 1);
          expect(slideActions[0], isA<ChatCustomSlidableAction>());

          final unmuteAction = slideActions[0] as ChatCustomSlidableAction;
          expect(unmuteAction.label, isA<String>());
          expect(unmuteAction.label, 'Unmute');
          expect(unmuteAction.icon, isA<Icon>());
          expect(
            (unmuteAction.icon as Icon).icon,
            equals(Icons.notifications_on_outlined),
          );
          expect((unmuteAction.icon as Icon).size, equals(iconSize));
          expect(unmuteAction.backgroundColor, isA<Color>());
          expect(
            unmuteAction.backgroundColor,
            equals(LinagoraRefColors.material().primary[50]),
          );
        });

        testWidgets('GIVEN room is not muted\n'
            'THEN return mute action ', (WidgetTester tester) async {
          when(room.membership).thenReturn(Membership.invite);
          when(room.pushRuleState).thenReturn(PushRuleState.notify);

          final List<Widget> slideActions = await makeTestable(tester);

          expect(slideActions, isNotNull);
          expect(slideActions.length, 1);
          expect(slideActions[0], isA<ChatCustomSlidableAction>());

          final unmuteAction = slideActions[0] as ChatCustomSlidableAction;
          expect(unmuteAction.label, isA<String>());
          expect(unmuteAction.label, 'Mute');
          expect(unmuteAction.icon, isA<Icon>());
          expect(
            (unmuteAction.icon as Icon).icon,
            equals(Icons.notifications_off_outlined),
          );
          expect((unmuteAction.icon as Icon).size, equals(iconSize));
          expect(unmuteAction.backgroundColor, isA<Color>());
          expect(
            unmuteAction.backgroundColor,
            equals(LinagoraRefColors.material().primary[40]),
          );
        });
      });

      group('GIVEN room is not invitation', () {
        testWidgets('GIVEN room is unread\n'
            'AND room is muted\n'
            'AND room is favourite\n'
            'THEN return read, unmute, and unpin actions\n', (
          WidgetTester tester,
        ) async {
          when(room.membership).thenReturn(Membership.join);
          when(room.isUnread).thenReturn(true);
          when(room.pushRuleState).thenReturn(PushRuleState.dontNotify);
          when(room.isFavourite).thenReturn(true);

          final List<Widget> slideActions = await makeTestable(tester);

          expect(slideActions, isNotNull);
          expect(slideActions.length, 3);
          expect(slideActions[0], isA<ChatCustomSlidableAction>());
          expect(slideActions[1], isA<ChatCustomSlidableAction>());
          expect(slideActions[2], isA<ChatCustomSlidableAction>());

          final readAction = slideActions[0] as ChatCustomSlidableAction;
          expect(readAction.label, isA<String>());
          expect(readAction.label, 'Read');
          expect(readAction.icon, isA<Icon>());
          expect(
            (readAction.icon as Icon).icon,
            equals(Icons.mark_chat_read_outlined),
          );
          expect((readAction.icon as Icon).size, equals(iconSize));
          expect(readAction.backgroundColor, isA<Color>());
          expect(
            readAction.backgroundColor,
            equals(LinagoraRefColors.material().tertiary[40]),
          );

          final unmuteAction = slideActions[1] as ChatCustomSlidableAction;
          expect(unmuteAction.label, isA<String>());
          expect(unmuteAction.label, 'Unmute');
          expect(unmuteAction.icon, isA<Icon>());
          expect(
            (unmuteAction.icon as Icon).icon,
            equals(Icons.notifications_on_outlined),
          );
          expect((unmuteAction.icon as Icon).size, equals(iconSize));
          expect(unmuteAction.backgroundColor, isA<Color>());
          expect(
            unmuteAction.backgroundColor,
            equals(LinagoraRefColors.material().primary[50]),
          );

          final unpinAction = slideActions[2] as ChatCustomSlidableAction;
          expect(unpinAction.label, isA<String>());
          expect(unpinAction.label, 'Unpin');
          expect(unpinAction.icon, isA<SvgPicture>());
          expect(
            (unpinAction.icon as SvgPicture).toString(),
            contains('assets/images/ic_unpin.svg'),
          );
          expect((unpinAction.icon as SvgPicture).width, equals(iconSize));
          expect(unpinAction.backgroundColor, isA<Color>());
          expect(
            unpinAction.backgroundColor,
            equals(LinagoraRefColors.material().tertiary[40]),
          );
        });

        testWidgets('GIVEN room is not unread\n'
            'AND room is not muted\n'
            'AND room is not favourite\n'
            'THEN return unread, mute and pin actions\n', (
          WidgetTester tester,
        ) async {
          when(room.membership).thenReturn(Membership.join);
          when(room.isUnread).thenReturn(false);
          when(room.pushRuleState).thenReturn(PushRuleState.notify);
          when(room.isFavourite).thenReturn(false);

          final List<Widget> slideActions = await makeTestable(tester);

          expect(slideActions, isNotNull);
          expect(slideActions.length, 3);
          expect(slideActions[0], isA<ChatCustomSlidableAction>());
          expect(slideActions[1], isA<ChatCustomSlidableAction>());
          expect(slideActions[2], isA<ChatCustomSlidableAction>());

          final unreadAction = slideActions[0] as ChatCustomSlidableAction;
          expect(unreadAction.label, isA<String>());
          expect(unreadAction.label, 'Unread');
          expect(unreadAction.icon, isA<Icon>());
          expect(
            (unreadAction.icon as Icon).icon,
            equals(Icons.mark_chat_unread_outlined),
          );
          expect((unreadAction.icon as Icon).size, equals(iconSize));
          expect(unreadAction.backgroundColor, isA<Color>());
          expect(
            unreadAction.backgroundColor,
            equals(Colors.deepPurpleAccent[200]),
          );

          final muteAction = slideActions[1] as ChatCustomSlidableAction;
          expect(muteAction.label, isA<String>());
          expect(muteAction.label, 'Mute');
          expect(muteAction.icon, isA<Icon>());
          expect(
            (muteAction.icon as Icon).icon,
            equals(Icons.notifications_off_outlined),
          );
          expect((muteAction.icon as Icon).size, equals(iconSize));
          expect(muteAction.backgroundColor, isA<Color>());
          expect(
            muteAction.backgroundColor,
            equals(LinagoraRefColors.material().primary[40]),
          );

          final pinAction = slideActions[2] as ChatCustomSlidableAction;
          expect(pinAction.label, isA<String>());
          expect(pinAction.label, 'Pin');
          expect(pinAction.icon, isA<Icon>());
          expect(
            (pinAction.icon as Icon).icon,
            equals(Icons.push_pin_outlined),
          );
          expect((pinAction.icon as Icon).size, equals(iconSize));
          expect(pinAction.backgroundColor, isA<Color>());
          expect(pinAction.backgroundColor, equals(Colors.tealAccent[700]));
        });
      });
    });
  });
}
