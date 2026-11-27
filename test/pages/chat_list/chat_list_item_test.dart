import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/config/feed_config.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/domain/model/room/room_preview_result.dart';
import 'package:twake_chat/generated/assets.gen.dart';
import 'package:twake_chat/pages/chat/events/message_time_style.dart';
import 'package:twake_chat/pages/chat/seen_by_row.dart';
import 'package:twake_chat/pages/chat_list/chat_list_item.dart';
import 'package:twake_chat/presentation/model/chat_list/room_list_row.dart';
import 'package:twake_chat/presentation/model/chat_list/space_row_data.dart';
import 'package:twake_chat/utils/custom_scroll_behaviour.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/avatar/avatar_with_kind_badge.dart';
import 'package:twake_chat/widgets/avatar/person_presence_badge.dart';
import 'package:twake_chat/domain/presence/entities/person_presence.dart';
import 'package:twake_chat/providers/person_presence_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/widgets/theme_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart'
    show LinagoraRefColors, TwakeListItem;
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

/// [child] in the app's theme, under a provider scope (the display
/// preferences of the device are read through Riverpod).
Widget wrap(Widget child) {
  return ProviderScope(child: _themed(child));
}

Widget _themed(Widget child) {
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

  SpaceRowData spaceData({int mentionCount = 0}) => SpaceRowData(
    fold: SpaceFold.none,
    unreadCount: 0,
    mentionCount: mentionCount,
    onToggleFold: () {},
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

  testWidgets('names the mention badge of a space for a screen reader', (
    tester,
  ) async {
    final room = buildRoom(name: 'Team');

    await tester.pumpWidget(
      wrap(ChatListItem(room, space: spaceData(mentionCount: 1))),
    );
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'You were mentioned',
      ),
      findsOneWidget,
    );
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

    testWidgets('build_whenSpace_keepsTheBadgeAboveTheDivider', (tester) async {
      // Arrange
      final room = buildRoom(name: 'Team');
      when(room.isDirectChat).thenReturn(false);
      when(room.isSpace).thenReturn(true);

      // Act
      await tester.pumpWidget(wrap(ChatListItem(room, space: spaceData())));
      await tester.pump();

      // Assert
      final row = tester.getRect(find.byType(TwakeListItem));
      final badge = tester.getRect(
        find.descendant(
          of: find.byType(AvatarWithKindBadge),
          matching: find.byType(Icon),
        ),
      );
      expect(badge.bottom, lessThanOrEqualTo(row.bottom - 1));
    });

    testWidgets('build_whenSpace_matchesTheRoomAvatarAndRowSize', (
      tester,
    ) async {
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
      final avatars = find.byType(AvatarWithKindBadge);
      final rows = find.byType(TwakeListItem);
      expect(tester.getSize(avatars.at(0)), tester.getSize(avatars.at(1)));
      expect(
        tester.getSize(rows.at(0)).height,
        tester.getSize(rows.at(1)).height,
      );
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

  group('file preview', () {
    const pdfName = 'Contributions.pdf';
    const caption = 'Would this do?';
    final l10n = lookupL10n(const Locale('en'));

    Event pdfFrom(Room room, {String? caption}) => Event(
      eventId: r'$file',
      senderId: '@bob:server.tld',
      type: EventTypes.Message,
      content: {
        'msgtype': MessageTypes.File,
        'body': caption ?? pdfName,
        'filename': pdfName,
        'url': 'mxc://server.tld/pdf',
        'info': {'mimetype': 'application/pdf'},
      },
      originServerTs: DateTime(2020, 1, 1),
      status: EventStatus.synced,
      room: room,
    );

    MockRoom roomWithLastEvent({required bool isDirectChat}) {
      final room = buildRoom(name: 'Project Apollo');
      when(room.isDirectChat).thenReturn(isDirectChat);
      when(room.receiptState).thenReturn(LatestReceiptState.empty());
      when(room.typingUsers).thenReturn([]);
      final bob = User('@bob:server.tld', displayName: 'Bob', room: room);
      when(
        room.requestUser('@bob:server.tld', ignoreErrors: true),
      ).thenAnswer((_) async => bob);
      when(room.unsafeGetUserFromMemoryOrFallback(bob.id)).thenReturn(bob);
      return room;
    }

    Future<void> pumpPreview(
      WidgetTester tester,
      MockRoom room,
      Event event,
    ) async {
      await tester.pumpWidget(
        wrap(ChatListItem(room, previewResult: RoomPreviewFound(event))),
      );
      await tester.pumpAndSettle();
    }

    Finder svgAsset(String assetName) => find.byWidgetPredicate(
      (widget) =>
          widget is SvgPicture &&
          widget.bytesLoader is SvgAssetLoader &&
          (widget.bytesLoader as SvgAssetLoader).assetName == assetName,
    );

    for (final (chat, isDirectChat, withCaption, text) in [
      ('DirectChat', true, false, pdfName),
      ('DirectChat', true, true, caption),
      ('GroupChat', false, false, 'Bob: $pdfName'),
      ('GroupChat', false, true, 'Bob: $caption'),
    ]) {
      final sent = withCaption ? 'APdfWithCaption' : 'APdf';

      testWidgets('build_when${chat}LastEventIs${sent}_showsPdfIconAndText', (
        tester,
      ) async {
        final room = roomWithLastEvent(isDirectChat: isDirectChat);
        final event = pdfFrom(room, caption: withCaption ? caption : null);

        await pumpPreview(tester, room, event);

        expect(svgAsset(Assets.images.icFilePdf.path), findsOneWidget);
        expect(find.text(text), findsOneWidget);
        expect(find.text(l10n.sentAFile('Bob')), findsNothing);
      });

      testWidgets('build_when${chat}LastEventIs${sent}_keepsTwoLinesOfText', (
        tester,
      ) async {
        final room = roomWithLastEvent(isDirectChat: isDirectChat);
        final event = pdfFrom(room, caption: withCaption ? caption : null);

        await pumpPreview(tester, room, event);

        expect(tester.widget<Text>(find.text(text)).maxLines, 2);
      });
    }

    testWidgets('build_whenDirectChatFileCaptionIsMultiLine_showsItOnOneLine', (
      tester,
    ) async {
      final room = roomWithLastEvent(isDirectChat: true);
      final event = pdfFrom(room, caption: 'Would this\ndo?');

      await pumpPreview(tester, room, event);

      expect(find.text('Would this do?'), findsOneWidget);
    });

    testWidgets(
      'build_whenInvitedToDirectChatWhoseLastEventIsAPdf_saysItIsAnInvitation',
      (tester) async {
        final room = roomWithLastEvent(isDirectChat: true);
        when(room.membership).thenReturn(Membership.invite);
        final event = pdfFrom(room);

        await pumpPreview(tester, room, event);

        expect(find.text(l10n.youAreInvitedToThisChat), findsOneWidget);
        expect(svgAsset(Assets.images.icFilePdf.path), findsNothing);
      },
    );
  });

  group('presence dot', () {
    const peer = '@alice:server.tld';

    Widget withPresence(Widget child) => UncontrolledProviderScope(
      container: ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [
          syncedPersonPresenceProvider(peer).overrideWith(
            (ref) => Stream.value(
              const PersonPresence(status: PresenceStatus.online),
            ),
          ),
        ],
      ),
      child: wrap(child),
    );

    testWidgets('build_whenDirectChat_showsThePresenceOfThePeer', (
      tester,
    ) async {
      // Arrange
      final room = buildRoom(name: 'Alice');
      when(room.directChatMatrixID).thenReturn(peer);

      // Act
      await tester.pumpWidget(withPresence(ChatListItem(room)));
      await tester.pump();
      await tester.pump();

      // Assert
      final badge = tester.widget<PersonPresenceBadge>(
        find.byType(PersonPresenceBadge),
      );
      expect(badge.userId, peer);
      expect(find.byKey(const ValueKey('linagora-presence-dot')), findsOne);
    });

    testWidgets('build_whenGroup_showsNoPresence', (tester) async {
      // Arrange
      final room = buildRoom(name: 'Team');
      when(room.isDirectChat).thenReturn(false);
      when(room.directChatMatrixID).thenReturn(peer);

      // Act
      await tester.pumpWidget(withPresence(ChatListItem(room)));
      await tester.pump();
      await tester.pump();

      // Assert
      expect(find.byType(PersonPresenceBadge), findsNothing);
    });
  });
}
