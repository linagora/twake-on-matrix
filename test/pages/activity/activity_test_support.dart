import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/data/repository/activity/activity_mentions_repository.provider.dart';
import 'package:twake_chat/data/repository/activity/activity_reactions_repository.provider.dart';
import 'package:twake_chat/data/repository/activity/activity_repository.provider.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/domain/repository/activity/activity_repository.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/activity/activity_page.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import '../../domain/usecase/room/send_text_message_interactor_test.mocks.dart';
import '../../providers/fake_active_account.dart';
import 'activity_mentions_test_support.dart';
import 'activity_reactions_test_support.dart';

/// THR-M-12, slice 1: what the Activity tab reads from the sync data held in
/// memory (unread rooms, followed threads, unread mentions), as a test sets
/// it. [markRoomRead] behaves as the next sync would: the room is read, so
/// it leaves the list and its mentions leave the count.
class FakeActivityRepository implements ActivityRepository {
  FakeActivityRepository({
    List<ActivityItem> items = const [],
    int mentionCount = 0,
    Map<String, int> mentionsByRoom = const {},
  }) : _items = [...items],
       _mentionCount = mentionCount,
       _mentionsByRoom = {...mentionsByRoom};

  List<ActivityItem> _items;
  int _mentionCount;
  final Map<String, int> _mentionsByRoom;

  final _itemChanges = StreamController<List<ActivityItem>>.broadcast();
  final _countChanges = StreamController<int>.broadcast();

  /// The rooms « Mark as read » was asked for, in order.
  final List<String> markedRead = [];

  /// Set it to make « Mark as read » fail.
  Object? markReadError;

  @override
  Stream<List<ActivityItem>> watchActivity() async* {
    yield _items;
    yield* _itemChanges.stream;
  }

  @override
  Stream<int> watchUnreadMentionCount() async* {
    yield _mentionCount;
    yield* _countChanges.stream;
  }

  @override
  Future<void> markRoomRead(String roomId) async {
    markedRead.add(roomId);
    final error = markReadError;
    if (error != null) throw error;
    emit(
      _items
          .where(
            (item) =>
                !(item.kind == ActivityKind.unreadRoom &&
                    item.roomId == roomId),
          )
          .toList(),
    );
    setMentionCount(_mentionCount - (_mentionsByRoom.remove(roomId) ?? 0));
  }

  /// The sync brought a change: the list is now [items].
  void emit(List<ActivityItem> items) {
    _items = [...items];
    _itemChanges.add(_items);
  }

  void setMentionCount(int count) {
    _mentionCount = count;
    _countChanges.add(count);
  }

  Future<void> close() async {
    await _itemChanges.close();
    await _countChanges.close();
  }
}

/// The start of today, local time: an item at [todayAt] is today whatever
/// the hour the test runs (unless it runs across midnight).
DateTime get startOfToday {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// `12.today`: 12 o'clock today; `12.yesterday`: the day before.
extension ActivityHour on int {
  DateTime get today => (this, 0).today;

  DateTime get yesterday => (this, 0).yesterday;
}

/// `(11, 30).today`: 11:30 today; `(11, 30).yesterday`: the day before.
extension ActivityTime on (int, int) {
  Duration get _sinceMidnight => Duration(hours: $1, minutes: $2);

  DateTime get today => startOfToday.add(_sinceMidnight);

  DateTime get yesterday {
    final today = startOfToday;
    return DateTime(today.year, today.month, today.day - 1).add(_sinceMidnight);
  }
}

/// A room with unread messages, its last message by [author].
class UnreadRoomItem {
  const UnreadRoomItem({
    required this.roomId,
    required this.roomName,
    required this.time,
    this.unreadCount = 1,
    this.author = 'Bob Martin',
    this.lastMessage = 'see you there',
  });

  final String roomId;
  final String roomName;
  final DateTime time;
  final int unreadCount;
  final String author;
  final String lastMessage;

  ActivityItem get item => ActivityItem(
    kind: ActivityKind.unreadRoom,
    roomId: roomId,
    roomName: roomName,
    time: time,
    authorName: author,
    quote: lastMessage,
    unreadCount: unreadCount,
  );
}

/// A thread the user follows: its last reply by [author].
class FollowedThreadItem {
  const FollowedThreadItem({
    required this.roomId,
    required this.roomName,
    required this.rootId,
    required this.time,
    this.rootText = 'Release plan for Friday',
    this.author = 'Alice Durand',
    this.lastReply = 'Ship it',
    this.unreadCount = 0,
    this.isResolved = false,
  });

  final String roomId;
  final String roomName;
  final String rootId;
  final DateTime time;
  final String rootText;
  final String author;
  final String lastReply;
  final int unreadCount;
  final bool isResolved;

  ActivityItem get item => ActivityItem(
    kind: ActivityKind.reply,
    roomId: roomId,
    roomName: roomName,
    time: time,
    authorName: author,
    quote: lastReply,
    unreadCount: unreadCount,
    eventId: '${rootId}_last',
    threadRootId: rootId,
    threadTitle: rootText,
    isResolved: isResolved,
  );
}

/// Shown by the test router where the app would open a room or a thread.
String openedText(String location) => 'opened ${Uri.decodeFull(location)}';

/// A logged-in account: the client the app holds for [userId].
Client accountClient(String userId) {
  final client = MockClient();
  when(client.userID).thenReturn(userId);
  when(client.clientName).thenReturn('client-$userId');
  return client;
}

/// The account active when a spec starts; [switchActiveAccount] changes it.
class _StartingAccount extends FakeActiveAccount {
  _StartingAccount(this._first);

  final Client? _first;

  @override
  Client? build() => _first;
}

/// The user switches to the account of [client] (null: logged out), as the
/// account switcher does: the active client and user id follow.
Future<void> switchActiveAccount(WidgetTester tester, Client? client) async {
  ProviderScope.containerOf(
    tester.element(find.byType(ActivityPage)),
  ).read(fakeActiveAccountProvider.notifier).set(client);
  await tester.pumpAndSettle();
}

/// How a spec opens the Activity page. [account] is the active account
/// (`@me:example.org` by default). Without [repository], the page reads
/// the real repositories of [account] (a `ThreadAccount`); with it, the
/// mentions and the reactions are empty unless [mentions] or [reactions]
/// are given, so no spec reads the account. [settle] false:
/// something keeps loading (a progress turns), the page is not settled.
/// [wide]: a wide screen instead of a phone. [locale]: the language of the
/// app. [appTheme]: the theme of the app ([TwakeThemes.buildTheme]) instead
/// of the default Material one.
class ActivityPageSetup {
  const ActivityPageSetup({
    required this.repository,
    this.mentions,
    this.reactions,
    this.overrides = const [],
    this.settle = true,
    this.wide = false,
    this.account,
    this.locale = const Locale('en'),
    this.appTheme = false,
  });

  final FakeActivityRepository? repository;
  final FakeActivityMentionsRepository? mentions;
  final FakeActivityReactionsRepository? reactions;
  final List<Override> overrides;
  final bool settle;
  final bool wide;
  final Client? account;
  final Locale locale;
  final bool appTheme;

  /// The fakes of the repositories, none without [repository].
  List<Override> get repositoryOverrides => [
    if (repository case final repository?) ...[
      activityRepositoryProvider.overrideWithValue(repository),
      activityMentionsRepositoryProvider.overrideWithValue(
        mentions ?? FakeActivityMentionsRepository(),
      ),
      activityReactionsRepositoryProvider.overrideWithValue(
        reactions ?? _emptyReactions(),
      ),
    ],
  ];
}

/// No reaction: closed with the test.
FakeActivityReactionsRepository _emptyReactions() {
  final reactions = FakeActivityReactionsRepository();
  addTearDown(reactions.close);
  return reactions;
}

/// The Activity page as the tab shows it, in a router that also knows the
/// room and thread locations: opening an item shows « opened <location> »
/// and a « Back » button that returns to the Activity the way the app does
/// (pop on a phone, where the item was pushed; back to the tab's location
/// on a wide screen, where the item replaced it).
Future<void> pumpActivityPage(
  WidgetTester tester,
  ActivityPageSetup setup,
) async {
  _sizeTheView(tester, setup);
  if (!GetIt.instance.isRegistered<ResponsiveUtils>()) {
    GetIt.instance.registerSingleton(ResponsiveUtils());
  }
  final router = _activityRouter();
  addTearDown(router.dispose);
  final repository = setup.repository;
  if (repository != null) addTearDown(repository.close);
  final reactions = setup.reactions;
  if (reactions != null) addTearDown(reactions.close);
  await tester.pumpWidget(_activityApp(setup, router));
  await _settleUnlessLoading(tester, setup);
}

/// A phone (or a wide screen), tall enough for every row of a test.
void _sizeTheView(WidgetTester tester, ActivityPageSetup setup) {
  tester.view.physicalSize = setup.wide
      ? const Size(1280 * 3, 1600 * 3)
      : const Size(390 * 3, 1600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

GoRouter _activityRouter() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const ActivityPage()),
    GoRoute(
      path: '/rooms/:roomid',
      builder: _opened,
      routes: [GoRoute(path: 'threads/:rootid', builder: _opened)],
    ),
  ],
);

Widget _opened(BuildContext context, GoRouterState state) => Scaffold(
  body: Column(
    children: [
      Text(openedText(state.uri.toString())),
      TextButton(
        onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        child: const Text('Back'),
      ),
    ],
  ),
);

Widget _activityApp(ActivityPageSetup setup, GoRouter router) => ProviderScope(
  retry: (_, _) => null,
  overrides: [
    // Always an account, as behind the login: the active client and
    // user id follow [switchActiveAccount].
    ...activeAccountOverridesFollowing(),
    fakeActiveAccountProvider.overrideWith(
      () => _StartingAccount(setup.account ?? accountClient('@me:example.org')),
    ),
    ...setup.repositoryOverrides,
    ...setup.overrides,
  ],
  child: MaterialApp.router(
    routerConfig: router,
    locale: setup.locale,
    builder: setup.appTheme ? _withAppTheme : null,
    localizationsDelegates: L10n.localizationsDelegates,
    supportedLocales: L10n.supportedLocales,
  ),
);

Widget _withAppTheme(BuildContext context, Widget? child) => Theme(
  data: TwakeThemes.buildTheme(context, Brightness.light),
  child: child!,
);

Future<void> _settleUnlessLoading(
  WidgetTester tester,
  ActivityPageSetup setup,
) async {
  if (setup.settle) {
    await tester.pumpAndSettle();
  } else {
    await _pumpWhileLoading(tester);
  }
}

/// Something keeps loading (a progress turns): no settling.
Future<void> _pumpWhileLoading(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Picks the filter chip labelled [label] of the Activity.
Future<void> selectFilter(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).first);
  await tester.pumpAndSettle();
}

/// As [selectFilter], while something keeps loading: no settling.
Future<void> selectFilterWhileLoading(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).first);
  await _pumpWhileLoading(tester);
}

/// The weight [text] is drawn with, whether it is a [Text] of its own or a
/// span of a rich text (« Bob reacted… »).
FontWeight? fontWeightOf(WidgetTester tester, Pattern text) => find
    .byType(RichText)
    .evaluate()
    .map((element) => _weightIn((element.widget as RichText).text, text, null))
    .nonNulls
    .firstOrNull;

/// The weight of the first span of [span] (itself included) holding [text],
/// depth first, with the style it inherits.
FontWeight? _weightIn(InlineSpan span, Pattern text, TextStyle? inherited) {
  if (span is! TextSpan) return null;
  final style = inherited?.merge(span.style) ?? span.style;
  if (span.text?.contains(text) ?? false) {
    return style?.fontWeight ?? FontWeight.normal;
  }
  return (span.children ?? const <InlineSpan>[])
      .map((child) => _weightIn(child, text, style))
      .nonNulls
      .firstOrNull;
}

/// The lines [text] takes on screen.
int linesOf(WidgetTester tester, Pattern text) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.textContaining(text, findRichText: true).first,
  );
  return paragraph
      .getBoxesForSelection(
        TextSelection(
          baseOffset: 0,
          extentOffset: paragraph.text.toPlainText().length,
        ),
      )
      .map((box) => box.top)
      .toSet()
      .length;
}
