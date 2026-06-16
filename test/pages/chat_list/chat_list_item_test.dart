import 'package:fluffychat/config/localizations/localization_service.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item.dart';
import 'package:fluffychat/utils/custom_scroll_behaviour.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/theme_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

import 'chat_list_item_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Room>(), MockSpec<Client>()])
void main() {
  setUpAll(() {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
  });

  MockRoom buildRoom({required String name, String id = '!room:server.tld'}) {
    final room = MockRoom();
    final client = MockClient();
    when(client.userID).thenReturn('@me:server.tld');
    when(room.client).thenReturn(client);
    when(room.id).thenReturn(id);
    when(room.name).thenReturn(name);
    when(room.membership).thenReturn(Membership.join);
    when(room.isDirectChat).thenReturn(true);
    when(room.encrypted).thenReturn(false);
    when(room.isFavourite).thenReturn(false);
    when(room.pushRuleState).thenReturn(PushRuleState.notify);
    when(room.isUnreadOrInvited).thenReturn(false);
    when(room.hasNewMessages).thenReturn(false);
    when(room.notificationCount).thenReturn(0);
    when(room.lastEvent).thenReturn(null);
    when(room.latestEventReceivedTime).thenReturn(DateTime(2020, 1, 1));
    when(
      room.getLocalizedDisplayname(any),
    ).thenReturn(name.isEmpty ? 'Resolved Hero Name' : name);
    when(room.loadHeroUsers()).thenAnswer((_) async => <User>[]);
    return room;
  }

  Widget wrap(Widget child) {
    return ThemeBuilder(
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
        theme: TwakeThemes.buildTheme(context, Brightness.light, primaryColor),
        home: Scaffold(body: child),
      ),
    );
  }

  // Pumps a [ChatListItem] inside a parent whose room can be swapped in place,
  // so one harness covers both plain rebuilds and state recycling. Returns a
  // setter that replaces the current room and rebuilds the item.
  Future<void Function(Room)> pumpItem(
    WidgetTester tester,
    Room initialRoom,
  ) async {
    var current = initialRoom;
    late StateSetter setItemState;
    await tester.pumpWidget(
      wrap(
        StatefulBuilder(
          builder: (context, setState) {
            setItemState = setState;
            return ChatListItem(current);
          },
        ),
      ),
    );
    await tester.pump();
    return (room) => setItemState(() => current = room);
  }

  testWidgets(
    'loads hero users once for a nameless room and never again on rebuild',
    (tester) async {
      final room = buildRoom(name: '');
      final rebuild = await pumpItem(tester, room);

      verify(room.loadHeroUsers()).called(1);

      // Rebuild in place with the same room: build() re-runs, the load does not.
      for (var i = 0; i < 3; i++) {
        rebuild(room);
        await tester.pump();
      }

      verifyNever(room.loadHeroUsers());
    },
  );

  testWidgets('does not load hero users when the room already has a name', (
    tester,
  ) async {
    final room = buildRoom(name: 'Project Apollo');

    await pumpItem(tester, room);

    verifyNever(room.loadHeroUsers());
  });

  testWidgets(
    'reloads hero users when the state is recycled for a different room '
    '(unkeyed lists like archive / space views)',
    (tester) async {
      final roomA = buildRoom(name: '', id: '!a:server.tld');
      final roomB = buildRoom(name: '', id: '!b:server.tld');

      final recycle = await pumpItem(tester, roomA);
      verify(roomA.loadHeroUsers()).called(1);
      verifyNever(roomB.loadHeroUsers());

      // Recycle the state for roomB -> didUpdateWidget must reload its heroes.
      recycle(roomB);
      await tester.pump();

      verify(roomB.loadHeroUsers()).called(1);
    },
  );
}
