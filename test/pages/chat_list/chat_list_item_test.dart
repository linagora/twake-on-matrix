import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/domain/model/room/room_preview_result.dart';
import 'package:twake_chat/pages/chat/events/message_time_style.dart';
import 'package:twake_chat/pages/chat/seen_by_row.dart';
import 'package:twake_chat/pages/chat_list/chat_list_item.dart';
import 'package:twake_chat/utils/custom_scroll_behaviour.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/theme_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

import 'chat_list_item_test.mocks.dart';

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

class _FakeUser extends Fake implements User {}

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

@GenerateNiceMocks([MockSpec<Room>(), MockSpec<Client>()])
void main() {
  setUpAll(() {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
  });

  testWidgets('loads hero users to resolve the name of a nameless room', (
    tester,
  ) async {
    final room = buildRoom(name: '');

    await tester.pumpWidget(wrap(ChatListItem(room)));
    await tester.pump();

    verify(room.loadHeroUsers()).called(greaterThanOrEqualTo(1));
  });

  testWidgets('does not load hero users when the room already has a name', (
    tester,
  ) async {
    final room = buildRoom(name: 'Project Apollo');

    await tester.pumpWidget(wrap(ChatListItem(room)));
    await tester.pump();

    verifyNever(room.loadHeroUsers());
  });

  testWidgets('shows the seen status computed with the preview', (
    tester,
  ) async {
    final room = buildRoom(name: 'Project Apollo');
    when(room.receiptState).thenReturn(LatestReceiptState.empty());
    when(room.typingUsers).thenReturn([]);
    final event = Event(
      eventId: r'$own',
      senderId: '@me:server.tld',
      type: EventTypes.Message,
      content: {'msgtype': 'm.text', 'body': 'hello'},
      originServerTs: DateTime(2020, 1, 1),
      status: EventStatus.synced,
      room: room,
    );

    await tester.pumpWidget(
      wrap(
        ChatListItem(
          room,
          previewResult: RoomPreviewFound(event, seenByUsers: [_FakeUser()]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(
      find.descendant(of: find.byType(SeenByRow), matching: find.byType(Icon)),
    );
    expect(icon.color, MessageTimeStyle.seenByRowIconPrimaryColor(false));
  });
}
