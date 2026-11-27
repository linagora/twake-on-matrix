import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/config/feed_config.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/domain/model/room/room_preview_result.dart';
import 'package:twake_chat/pages/chat/events/message_time_style.dart';
import 'package:twake_chat/pages/chat/seen_by_row.dart';
import 'package:twake_chat/pages/chat_list/chat_list_item.dart';
import 'package:twake_chat/presentation/model/chat_list/room_list_row.dart';
import 'package:twake_chat/presentation/model/chat_list/space_row_data.dart';
import 'package:twake_chat/utils/custom_scroll_behaviour.dart';
import 'package:twake_chat/utils/date_time_extension.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/avatar/avatar_with_kind_badge.dart';
import 'package:twake_chat/widgets/theme_builder.dart';
import 'package:twake_chat/widgets/twake_components/unread_count_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart'
    show LinagoraRefColors, LinagoraSysColors;
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
  when(room.summary).thenReturn(RoomSummary.fromJson({}));
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

  testWidgets('loads hero users once when the same row rebuilds', (
    tester,
  ) async {
    final room = buildRoom(name: '');

    await tester.pumpWidget(wrap(ChatListItem(room)));
    await tester.pump();
    await tester.pumpWidget(wrap(ChatListItem(room, activeChat: true)));
    await tester.pump();

    verify(room.loadHeroUsers()).called(1);
  });

  testWidgets('loads hero users again when the heroes of the room change', (
    tester,
  ) async {
    final room = buildRoom(name: '');
    when(room.summary).thenReturn(
      RoomSummary.fromJson({
        'm.heroes': ['@alice:server.tld'],
      }),
    );

    await tester.pumpWidget(wrap(ChatListItem(room)));
    await tester.pump();
    // A sync replaces the summary of the room with a new one.
    when(room.summary).thenReturn(
      RoomSummary.fromJson({
        'm.heroes': ['@bob:server.tld'],
      }),
    );
    await tester.pumpWidget(wrap(ChatListItem(room, activeChat: true)));
    await tester.pump();

    verify(room.loadHeroUsers()).called(2);
  });

  testWidgets('loads hero users again when the membership changes', (
    tester,
  ) async {
    final room = buildRoom(name: '');
    when(room.membership).thenReturn(Membership.invite);

    await tester.pumpWidget(wrap(ChatListItem(room)));
    await tester.pump();
    when(room.membership).thenReturn(Membership.join);
    await tester.pumpWidget(wrap(ChatListItem(room, activeChat: true)));
    await tester.pump();

    verify(room.loadHeroUsers()).called(2);
  });

  testWidgets('loads the peer when the display name adds it to empty heroes', (
    tester,
  ) async {
    final room = buildRoom(name: '');
    final summary = RoomSummary.fromJson({'m.heroes': <String>[]});
    when(room.summary).thenReturn(summary);
    // As the SDK does: an empty hero list gets the DM peer added in place.
    when(room.getLocalizedDisplayname(any)).thenAnswer((_) {
      final heroes = summary.mHeroes!;
      if (heroes.isEmpty) heroes.add('@peer:server.tld');
      return 'Peer';
    });

    await tester.pumpWidget(wrap(ChatListItem(room)));
    await tester.pump();
    await tester.pumpWidget(wrap(ChatListItem(room, activeChat: true)));
    await tester.pump();

    verify(room.loadHeroUsers()).called(2);
  });

  SpaceRowData spaceData({
    SpaceFold fold = SpaceFold.none,
    int roomCount = 0,
    int unreadCount = 0,
    int mentionCount = 0,
    VoidCallback? onToggleFold,
  }) => SpaceRowData(
    fold: fold,
    roomCount: roomCount,
    unreadCount: unreadCount,
    mentionCount: mentionCount,
    onToggleFold: onToggleFold ?? () {},
  );

  testWidgets('says an invited space is an invitation', (tester) async {
    final room = buildRoom(name: 'Team');
    when(room.membership).thenReturn(Membership.invite);

    await tester.pumpWidget(wrap(ChatListItem(room, space: spaceData())));
    await tester.pump();

    expect(find.text('Invited'), findsOneWidget);
  });

  testWidgets('says nothing of invitation on a joined space', (tester) async {
    final room = buildRoom(name: 'Team');

    await tester.pumpWidget(wrap(ChatListItem(room, space: spaceData())));
    await tester.pump();

    expect(find.text('Invited'), findsNothing);
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

  group('space row', () {
    MockRoom buildSpace({String name = 'Team'}) {
      final room = buildRoom(name: name, id: '!space:server.tld');
      when(room.isDirectChat).thenReturn(false);
      when(room.isSpace).thenReturn(true);
      return room;
    }

    Future<void> pumpSpace(
      WidgetTester tester,
      SpaceRowData space, {
      MockRoom? room,
    }) async {
      await tester.pumpWidget(
        wrap(ChatListItem(room ?? buildSpace(), space: space)),
      );
      await tester.pump();
    }

    /// The style [text] is painted with, alone or inside a longer text.
    TextStyle? paintedStyleOf(WidgetTester tester, String text) {
      TextStyle? found;
      void visit(InlineSpan span, TextStyle? inherited) {
        if (span is! TextSpan) return;
        final style = inherited?.merge(span.style) ?? span.style;
        if (span.text?.contains(text) ?? false) found = style;
        for (final child in span.children ?? const <InlineSpan>[]) {
          visit(child, style);
        }
      }

      for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
        visit(rich.text, null);
      }
      return found;
    }

    Finder says(String text) => find.textContaining(text, findRichText: true);

    const downChevrons = [
      Icons.expand_more,
      Icons.expand_more_rounded,
      Icons.expand_more_outlined,
      Icons.keyboard_arrow_down,
      Icons.keyboard_arrow_down_rounded,
      Icons.keyboard_arrow_down_outlined,
    ];
    const upChevrons = [
      Icons.expand_less,
      Icons.expand_less_rounded,
      Icons.expand_less_outlined,
      Icons.keyboard_arrow_up,
      Icons.keyboard_arrow_up_rounded,
      Icons.keyboard_arrow_up_outlined,
    ];
    const sideChevrons = [
      Icons.chevron_right,
      Icons.chevron_left,
      Icons.arrow_drop_down,
      Icons.arrow_drop_up,
      Icons.arrow_right,
    ];

    List<IconData?> chevronsShown(WidgetTester tester) => [
      for (final icon in tester.widgetList<Icon>(find.byType(Icon)))
        if ([
          ...downChevrons,
          ...upChevrons,
          ...sideChevrons,
        ].contains(icon.icon))
          icon.icon,
    ];

    testWidgets('a space with nothing unread says how many rooms it holds', (
      tester,
    ) async {
      await pumpSpace(tester, spaceData(fold: SpaceFold.folded, roomCount: 4));

      expect(says('4 rooms'), findsOneWidget);
      expect(says('unread'), findsNothing);
      expect(says('·'), findsNothing);
    });

    testWidgets('a space with one room says « 1 room »', (tester) async {
      await pumpSpace(tester, spaceData(fold: SpaceFold.folded, roomCount: 1));

      expect(says('1 room'), findsOneWidget);
      expect(says('1 rooms'), findsNothing);
    });

    testWidgets('a space with unread messages says « 4 rooms · 2 unread »', (
      tester,
    ) async {
      await pumpSpace(
        tester,
        spaceData(fold: SpaceFold.folded, roomCount: 4, unreadCount: 2),
      );

      expect(says('4 rooms'), findsOneWidget);
      expect(says('·'), findsOneWidget);
      expect(says('2 unread'), findsOneWidget);
    });

    testWidgets('only the unread part is in the primary colour, semi-bold', (
      tester,
    ) async {
      await pumpSpace(
        tester,
        spaceData(fold: SpaceFold.folded, roomCount: 4, unreadCount: 2),
      );

      final primary = LinagoraSysColors.material().primary;
      final unread = paintedStyleOf(tester, '2 unread');
      expect(unread?.color, primary);
      expect(unread?.fontWeight, FontWeight.w600);
      final rooms = paintedStyleOf(tester, '4 rooms');
      expect(rooms, isNotNull);
      expect(rooms?.color, isNot(primary));
    });

    testWidgets('the summary is smaller than the name', (tester) async {
      await pumpSpace(tester, spaceData(fold: SpaceFold.folded, roomCount: 4));

      expect(says('4 rooms'), findsOneWidget);
      expect(
        tester.getSize(says('4 rooms')).height,
        lessThan(tester.getSize(find.text('Team')).height),
      );
      expect(
        tester.getTopLeft(says('4 rooms')).dy,
        greaterThan(tester.getTopLeft(find.text('Team')).dy),
      );
    });

    testWidgets('a space shows no date', (tester) async {
      await pumpSpace(tester, spaceData(fold: SpaceFold.folded, roomCount: 4));

      final date = DateTime(
        2020,
        1,
        1,
      ).localizedTimeShort(tester.element(find.byType(ChatListItem)));
      expect(date, isNotEmpty);
      expect(says(date), findsNothing);
    });

    testWidgets('a muted space shows no mute icon', (tester) async {
      final room = buildSpace();
      when(room.pushRuleState).thenReturn(PushRuleState.dontNotify);

      await pumpSpace(
        tester,
        spaceData(fold: SpaceFold.folded, roomCount: 4),
        room: room,
      );

      expect(find.byIcon(Icons.volume_off_outlined), findsNothing);
      expect(find.byIcon(Icons.volume_off), findsNothing);
      expect(find.byIcon(Icons.notifications_off_outlined), findsNothing);
    });

    testWidgets('a space with unread messages and a mention shows no badge', (
      tester,
    ) async {
      await pumpSpace(
        tester,
        spaceData(
          fold: SpaceFold.folded,
          roomCount: 4,
          unreadCount: 28,
          mentionCount: 1,
        ),
      );

      expect(find.byType(UnreadCountBadge), findsNothing);
      expect(find.text('28'), findsNothing);
      expect(find.text('@'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'You were mentioned',
        ),
        findsNothing,
      );
    });

    testWidgets('a space row holds no « + » button', (tester) async {
      await pumpSpace(tester, spaceData(fold: SpaceFold.open, roomCount: 4));

      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byTooltip('Add subspace to Team'), findsNothing);
    });

    testWidgets('a closed space ends with one chevron down that shows its '
        'rooms', (tester) async {
      await pumpSpace(
        tester,
        spaceData(fold: SpaceFold.folded, roomCount: 4, unreadCount: 2),
      );

      expect(find.byTooltip('Show the rooms of Team'), findsOneWidget);
      final chevrons = chevronsShown(tester);
      expect(chevrons, hasLength(1));
      expect(downChevrons, contains(chevrons.single));
      expect(
        tester.getCenter(find.byTooltip('Show the rooms of Team')).dx,
        greaterThan(tester.getTopRight(says('4 rooms')).dx),
      );
    });

    testWidgets('an open space ends with one chevron up that hides its '
        'rooms', (tester) async {
      await pumpSpace(tester, spaceData(fold: SpaceFold.open, roomCount: 4));

      expect(find.byTooltip('Hide the rooms of Team'), findsOneWidget);
      final chevrons = chevronsShown(tester);
      expect(chevrons, hasLength(1));
      expect(upChevrons, contains(chevrons.single));
    });

    for (final (fold, tooltip) in [
      (SpaceFold.folded, 'Show the rooms of Team'),
      (SpaceFold.open, 'Hide the rooms of Team'),
    ]) {
      testWidgets('a tap on the chevron of a ${fold.name} space toggles the '
          'fold', (tester) async {
        var toggled = 0;
        await pumpSpace(
          tester,
          spaceData(fold: fold, roomCount: 4, onToggleFold: () => toggled++),
        );

        await tester.tap(find.byTooltip(tooltip));

        expect(toggled, 1);
      });
    }

    testWidgets('a space has no kind badge on its avatar', (tester) async {
      await pumpSpace(tester, spaceData(roomCount: 4));

      expect(find.byType(AvatarWithKindBadge), findsNothing);
    });

    testWidgets('the avatar of a space is a rounded square, not a circle', (
      tester,
    ) async {
      await pumpSpace(tester, spaceData(roomCount: 4));

      // Every square box of the row that clips or paints a shape: the avatar.
      // Each gives its corner radius as a share of its side: 0.5 is a circle.
      final corners = <double>[];
      final row = find.byType(ChatListItem);
      for (final element
          in find
              .descendant(
                of: row,
                matching: find.byWidgetPredicate(
                  (w) => w is ClipRRect || w is ClipOval || w is DecoratedBox,
                ),
              )
              .evaluate()) {
        final size = (element.renderObject! as RenderBox).size;
        if (size.width != size.height || size.width < 24) continue;
        final widget = element.widget;
        final decoration = widget is DecoratedBox ? widget.decoration : null;
        if (widget is ClipOval ||
            (decoration is BoxDecoration &&
                decoration.shape == BoxShape.circle)) {
          corners.add(0.5);
        } else if (widget is ClipRRect) {
          final radius = widget.borderRadius.resolve(TextDirection.ltr);
          corners.add(radius.topLeft.x / size.width);
        } else if (decoration is BoxDecoration &&
            decoration.borderRadius != null) {
          final radius = decoration.borderRadius!.resolve(TextDirection.ltr);
          corners.add(radius.topLeft.x / size.width);
        }
      }

      expect(corners, isNotEmpty);
      // The corner is rounded, well short of the half side of a circle.
      expect(corners, everyElement(allOf(greaterThan(0), lessThan(0.4))));
    });
  });

  group('mention badge', () {
    MockRoom unreadRoomWithMention({
      PushRuleState pushRuleState = PushRuleState.notify,
    }) {
      final room = buildRoom(name: 'Project Apollo');
      when(room.isDirectChat).thenReturn(false);
      when(room.receiptState).thenReturn(LatestReceiptState.empty());
      when(room.typingUsers).thenReturn([]);
      when(room.pushRuleState).thenReturn(pushRuleState);
      when(room.isUnreadOrInvited).thenReturn(true);
      when(room.hasNewMessages).thenReturn(true);
      when(room.highlightCount).thenReturn(1);
      when(room.notificationCount).thenReturn(3);
      return room;
    }

    Event plainMessageFromOther(Room room) => Event(
      eventId: r'$other',
      senderId: '@bob:server.tld',
      type: EventTypes.Message,
      content: {'msgtype': 'm.text', 'body': 'not a mention'},
      originServerTs: DateTime(2020, 1, 1),
      status: EventStatus.synced,
      room: room,
    );

    Color? badgeColor(WidgetTester tester, Finder child) {
      final box = tester.widget<DecoratedBox>(
        find.ancestor(of: child, matching: find.byType(DecoratedBox)).first,
      );
      return (box.decoration as BoxDecoration).color;
    }

    testWidgets('build_whenMentionIsNotTheLastMessage_showsTheAt', (
      tester,
    ) async {
      // Arrange
      final room = unreadRoomWithMention();

      // Act
      await tester.pumpWidget(
        wrap(
          ChatListItem(
            room,
            previewResult: RoomPreviewFound(plainMessageFromOther(room)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('@'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('build_whenMutedWithMention_greysTheAtAndTheCounter', (
      tester,
    ) async {
      // Arrange
      final room = unreadRoomWithMention(
        pushRuleState: PushRuleState.mentionsOnly,
      );

      // Act
      await tester.pumpWidget(
        wrap(
          ChatListItem(
            room,
            previewResult: RoomPreviewFound(plainMessageFromOther(room)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final grey = LinagoraRefColors.material().tertiary[30];
      expect(badgeColor(tester, find.text('@')), grey);
      expect(badgeColor(tester, find.text('3')), grey);
    });
  });

  group('kind badge', () {
    void makeFeed(MockRoom room) {
      when(room.getState(EventTypes.RoomCreate)).thenReturn(
        StrippedStateEvent(
          type: EventTypes.RoomCreate,
          content: {'type': FeedConfig.roomType},
          senderId: '@owner:server.tld',
          stateKey: '',
        ),
      );
    }

    AvatarKindBadge? shownBadge(WidgetTester tester) {
      final finder = find.byType(AvatarWithKindBadge);
      if (finder.evaluate().isEmpty) return null;
      return tester.widget<AvatarWithKindBadge>(finder).badge;
    }

    testWidgets('build_whenDirectChat_showsNoBadge', (tester) async {
      // Arrange
      final room = buildRoom(name: 'Alice');

      // Act
      await tester.pumpWidget(wrap(ChatListItem(room)));
      await tester.pump();

      // Assert
      expect(shownBadge(tester), isNull);
    });

    testWidgets('build_whenSpace_alignsTheTitleWithTheRooms', (tester) async {
      // Arrange
      final space = buildRoom(name: 'Team', id: '!space:server.tld');
      when(space.isDirectChat).thenReturn(false);
      when(space.isSpace).thenReturn(true);
      final room = buildRoom(name: 'General');
      when(room.isDirectChat).thenReturn(false);

      // Act
      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              ChatListItem(space, space: spaceData()),
              ChatListItem(room),
            ],
          ),
        ),
      );
      await tester.pump();

      // Assert
      expect(
        tester.getTopLeft(find.text('Team')).dx,
        tester.getTopLeft(find.text('General')).dx,
      );
    });

    for (final (description, joinRules, isFeed, badge) in [
      ('UnknownJoinRule', null, false, AvatarKindBadge.people),
      ('InviteOnlyGroup', JoinRules.invite, false, AvatarKindBadge.people),
      ('PublicGroup', JoinRules.public, false, AvatarKindBadge.public),
      ('PublicFeed', JoinRules.public, true, AvatarKindBadge.broadcast),
      ('PrivateFeed', JoinRules.invite, true, AvatarKindBadge.broadcast),
    ]) {
      testWidgets('build_when${description}_shows${badge.name}Badge', (
        tester,
      ) async {
        // Arrange
        final room = buildRoom(name: 'Team');
        when(room.isDirectChat).thenReturn(false);
        when(room.joinRules).thenReturn(joinRules);
        if (isFeed) makeFeed(room);

        // Act
        await tester.pumpWidget(wrap(ChatListItem(room)));
        await tester.pump();

        // Assert
        expect(shownBadge(tester), badge);
      });
    }
  });
}
