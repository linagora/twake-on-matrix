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
import 'package:twake_chat/data/repository/activity/activity_mentions_repository.provider.dart';
import 'package:twake_chat/data/repository/activity/activity_repository.provider.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';
import 'package:twake_chat/domain/repository/activity/activity_repository.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/activity/activity_page.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import '../../domain/usecase/room/send_text_message_interactor_test.mocks.dart';
import '../../providers/fake_active_account.dart';
import 'activity_mentions_test_support.dart';

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

DateTime todayAt(int hour, [int minute = 0]) =>
    startOfToday.add(Duration(hours: hour, minutes: minute));

DateTime yesterdayAt(int hour, [int minute = 0]) {
  final today = startOfToday;
  return DateTime(
    today.year,
    today.month,
    today.day - 1,
  ).add(Duration(hours: hour, minutes: minute));
}

/// A room with unread messages, its last message by [author].
ActivityItem unreadRoomItem({
  required String roomId,
  required String roomName,
  required DateTime time,
  int unreadCount = 1,
  String author = 'Bob Martin',
  String lastMessage = 'see you there',
}) => ActivityItem(
  kind: ActivityKind.unreadRoom,
  roomId: roomId,
  roomName: roomName,
  time: time,
  authorName: author,
  quote: lastMessage,
  unreadCount: unreadCount,
);

/// A thread the user follows: its last reply by [author].
ActivityItem followedThreadItem({
  required String roomId,
  required String roomName,
  required String rootId,
  required DateTime time,
  String rootText = 'Release plan for Friday',
  String author = 'Alice Durand',
  String lastReply = 'Ship it',
  int unreadCount = 0,
  bool isResolved = false,
}) => ActivityItem(
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

/// The Activity page as the tab shows it, in a router that also knows the
/// room and thread locations: opening an item shows « opened <location> »
/// and a « Back » button that returns to the Activity the way the app does
/// (pop on a phone, where the item was pushed; back to the tab's location
/// on a wide screen, where the item replaced it).
///
/// The mentions are empty unless [mentions] is given, so no spec reads the
/// account. [account] is the active account (`@me:example.org` by default).
Future<void> pumpActivityPage(
  WidgetTester tester, {
  required FakeActivityRepository repository,
  FakeActivityMentionsRepository? mentions,
  List<Override> overrides = const [],
  bool settle = true,
  bool wide = false,
  Client? account,
}) async {
  // A phone (or a wide screen), tall enough for every row of a test.
  tester.view.physicalSize = wide
      ? const Size(1280 * 3, 1600 * 3)
      : const Size(390 * 3, 1600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  if (!GetIt.instance.isRegistered<ResponsiveUtils>()) {
    GetIt.instance.registerSingleton(ResponsiveUtils());
  }
  Widget opened(BuildContext context, GoRouterState state) => Scaffold(
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
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const ActivityPage()),
      GoRoute(
        path: '/rooms/:roomid',
        builder: opened,
        routes: [GoRoute(path: 'threads/:rootid', builder: opened)],
      ),
    ],
  );
  addTearDown(router.dispose);
  addTearDown(repository.close);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        // Always an account, as behind the login: the active client and
        // user id follow [switchActiveAccount].
        ...activeAccountOverridesFollowing(),
        fakeActiveAccountProvider.overrideWith(
          () => _StartingAccount(account ?? accountClient('@me:example.org')),
        ),
        activityRepositoryProvider.overrideWithValue(repository),
        activityMentionsRepositoryProvider.overrideWithValue(
          mentions ?? FakeActivityMentionsRepository(),
        ),
        ...overrides,
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // Something keeps loading (a progress turns): no settling.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Picks a filter chip of the Activity.
Future<void> selectFilter(
  WidgetTester tester,
  String label, {
  bool settle = true,
}) async {
  await tester.tap(find.text(label).first);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// The weight [text] is drawn with, whether it is a [Text] of its own or a
/// span of a rich text (« Bob reacted… »).
FontWeight? fontWeightOf(WidgetTester tester, String text) {
  for (final element in find.byType(RichText).evaluate()) {
    final widget = element.widget as RichText;
    FontWeight? found;
    void visit(InlineSpan span, TextStyle? inherited) {
      if (found != null) return;
      final style = inherited?.merge(span.style) ?? span.style;
      if (span is TextSpan) {
        if (span.text?.contains(text) ?? false) {
          found = style?.fontWeight ?? FontWeight.normal;
          return;
        }
        for (final child in span.children ?? const <InlineSpan>[]) {
          visit(child, style);
        }
      }
    }

    visit(widget.text, null);
    if (found != null) return found;
  }
  return null;
}

/// The lines [text] takes on screen.
int linesOf(WidgetTester tester, String text) {
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
