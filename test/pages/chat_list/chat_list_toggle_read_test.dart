import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_list/chat_list.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/twake_app.dart';

import 'chat_list_toggle_read_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Room>(), MockSpec<Event>()])
void main() {
  late MockRoom room;
  late bool flagBefore;

  // Threads off: toggleRead marks the room only, not its threads.
  setUp(() {
    flagBefore = AppConfig.threadsEnabled;
    AppConfig.threadsEnabled = false;
    GetIt.instance.registerSingleton(ResponsiveUtils());
    room = MockRoom();
    when(room.isUnread).thenReturn(true);
    when(room.markedUnread).thenReturn(true);
    when(room.markUnread(any)).thenAnswer((_) async {});
    when(
      room.setReadMarker(any, mRead: anyNamed('mRead')),
    ).thenAnswer((_) async {});
  });

  tearDown(() {
    AppConfig.threadsEnabled = flagBefore;
    return GetIt.instance.reset();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (context) => MaterialApp(
          navigatorKey: TwakeApp.routerKey = GlobalKey<NavigatorState>(),
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          theme: TwakeThemes.buildTheme(context, Brightness.light, null),
          home: const Scaffold(),
        ),
      ),
    );
  }

  Future<void> toggleRead(WidgetTester tester) async {
    unawaited(ChatListController().toggleRead(room));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('toggleRead_onRoomWithoutLastEvent_clearsUnreadWithoutError', (
    tester,
  ) async {
    // Arrange
    when(room.lastEvent).thenReturn(null);
    await pumpApp(tester);

    // Act
    await toggleRead(tester);

    // Assert
    verify(room.markUnread(false)).called(1);
    verifyNever(room.setReadMarker(any, mRead: anyNamed('mRead')));
    expect(find.textContaining('Null check'), findsNothing);
  });

  testWidgets('toggleRead_onRoomWithLastEvent_sendsReceiptOnIt', (
    tester,
  ) async {
    // Arrange
    final event = MockEvent();
    when(event.eventId).thenReturn(r'$last');
    when(room.lastEvent).thenReturn(event);
    await pumpApp(tester);

    // Act
    await toggleRead(tester);

    // Assert
    verify(room.markUnread(false)).called(1);
    verify(room.setReadMarker(r'$last', mRead: r'$last')).called(1);
  });

  testWidgets(
    'toggleRead_onManuallyUnreadRoomWithOwnLastEvent_stillSendsReceipt',
    (tester) async {
      // Arrange
      final event = MockEvent();
      when(event.eventId).thenReturn(r'$own');
      when(room.lastEvent).thenReturn(event);
      when(room.hasNewMessages).thenReturn(false);
      var markedUnread = true;
      when(room.isUnread).thenAnswer((_) => markedUnread);
      when(room.markUnread(false)).thenAnswer((_) async {
        markedUnread = false;
      });
      await pumpApp(tester);

      // Act
      await toggleRead(tester);

      // Assert
      verify(room.markUnread(false)).called(1);
      verify(room.setReadMarker(r'$own', mRead: r'$own')).called(1);
    },
  );
}
