import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/model/thread/thread_unread_state.dart';
import 'package:twake_chat/utils/icon_badge/icon_badge_updater.dart';

import 'icon_badge_fakes.dart';

/// Issue #3635 (decided by Clément): on iOS the notification extension
/// writes the icon badge from the push `counts.unread`, which Synapse counts
/// as 1 per room with any notification, threads included. With threads on,
/// the app rewrites the icon with its own count, the rooms unread (threads
/// as the room list counts them) or invited, after a sync that changes it
/// and when the app goes to the background; 0 removes the badge. Opening a
/// room writes the same count without that room. Threads off: only the
/// room-open write, as on main. Not on Android (push `number`) nor web.
///
/// Orchestrator decision (13/11): the extension's badge is applied only in
/// background (AppDelegate.swift:75 shows no remote notification in front),
/// so the count written is forgotten once the app goes to the background.
/// Decision change after review: coming back writes nothing, as the counts
/// are stale until the catch-up sync (no sync in background on iOS); that
/// first sync writes the count, even unchanged. The thread counters changing
/// after the sync (a follow lookup) write it too.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late bool flagBefore;

  setUp(() async {
    flagBefore = AppConfig.threadsEnabled;
    AppConfig.threadsEnabled = true;
    SharedPreferences.setMockInitialValues({});
    await appInForeground();
    _account = BadgeAccount();
    _badge = RecordedIconBadge();
  });

  tearDown(() {
    _updater?.dispose();
    _updater = null;
    AppConfig.threadsEnabled = flagBefore;
  });

  group('the rooms the icon counts', _roomCountTests);
  group('the threads the icon counts', _threadCountTests);
  group('a sync', _syncTests);
  group('the thread counters', _threadStoreTests);
  group('going to the background and back', _backgroundTests);
  group('opening a room', _roomOpenTests);
  group('threads off: as on main', _threadsOffTests);
  test('not on iOS, nothing is written', _notOnIosTest);
}

late BadgeAccount _account;
late RecordedIconBadge _badge;
IconBadgeUpdater? _updater;

IconBadgeUpdater _onIphone() =>
    _updater = IconBadgeUpdater(client: _account, badge: _badge, onIos: true);

void _roomCountTests() {
  test('a room with unread messages counts', () async {
    final general = _account.joined(_general)..notificationCount = 1;
    _account.joined(_random);
    _onIphone();

    await _account.syncs(general);

    expect(_badge.writes, [1]);
  });

  test('nothing unread removes the badge', () async {
    final general = _account.joined(_general);
    _onIphone();

    await _account.syncs(general);

    expect(_badge.writes, [removed]);
  });

  test('an invite counts', () async {
    final invite = _account.invitedTo(_random);
    _onIphone();

    await _account.syncs(invite);

    expect(_badge.writes, [1]);
  });

  test('a room the user left does not count', () async {
    final general = _account.joined(_general);
    _account.left(_random).notificationCount = 4;
    _onIphone();

    await _account.syncs(general);

    expect(_badge.writes, [removed]);
  });
}

void _threadCountTests() {
  test('a room whose only unread replies are in a thread the user does not '
      'follow does not count', () async {
    final general = _account.joined(_general);
    await _account.threadHas(_generalThread, _repliesOnly);
    _onIphone();

    await _account.syncs(general);

    expect(_badge.writes, [removed]);
  });

  test('a mention in a thread the user does not follow counts', () async {
    final general = _account.joined(_general);
    await _account.threadHas(_generalThread, _withMention);
    _onIphone();

    await _account.syncs(general);

    expect(_badge.writes, [1]);
  });

  test('unread replies in a thread the user follows count', () async {
    final general = _account.joined(_general);
    _account.threadUnread.markFollowed(_generalThread);
    await _account.threadHas(_generalThread, _repliesOnly);
    _onIphone();

    await _account.syncs(general);

    expect(_badge.writes, [1]);
  });

  test('a room counts once, whatever it has unread', () async {
    final general = _account.joined(_general)..notificationCount = 5;
    _account.threadUnread.markFollowed(_generalThread);
    await _account.threadHas(_generalThread, _withMention);
    _account.joined(_random).notificationCount = 1;
    _onIphone();

    await _account.syncs(general);

    expect(_badge.writes, [2]);
  });
}

void _syncTests() {
  test('a sync that changes the count writes the new count', () async {
    final general = _account.joined(_general)..notificationCount = 1;
    final random = _account.joined(_random);
    _onIphone();
    await _account.syncs(general);

    random.notificationCount = 1;
    await _account.syncs(random);

    expect(_badge.writes, [1, 2]);
  });

  test('a sync that leaves the count as it is writes nothing', () async {
    final general = _account.joined(_general)..notificationCount = 1;
    _onIphone();
    await _account.syncs(general);

    general.notificationCount = 3;
    await _account.syncs(general);

    expect(_badge.writes, [1]);
  });

  test('a sync that reads the last unread room removes the badge', () async {
    final general = _account.joined(_general)..notificationCount = 1;
    _onIphone();
    await _account.syncs(general);

    general.notificationCount = 0;
    await _account.syncs(general);

    expect(_badge.writes, [1, removed]);
  });
}

void _threadStoreTests() {
  test('a follow lookup that finishes after the sync writes the new '
      'count', () async {
    final general = _account.joined(_general);
    _account.answerLater();
    _onIphone();
    _account.threadGets(_generalThread, _repliesOnly);
    await _account.syncs(general);

    await _account.answersUserWroteIn(_generalThread);

    expect(_badge.writes, [removed, 1]);
  });
}

void _backgroundTests() {
  test('going to the background writes the count', () async {
    _account.joined(_general).notificationCount = 1;
    _onIphone();

    await appGoesToBackground();

    expect(_badge.writes, [1]);
  });

  test('coming back to the foreground writes nothing', () async {
    final general = _account.joined(_general)..notificationCount = 1;
    _onIphone();
    await _account.syncs(general);
    await appGoesToBackground();
    final before = [..._badge.writes];

    await appInForeground();

    expect(_badge.writes, before);
  });

  test('the first sync after coming back writes the count, even when '
      'unchanged', () async {
    final general = _account.joined(_general)..notificationCount = 1;
    _onIphone();
    await _account.syncs(general);
    await appGoesToBackground();
    await appInForeground();
    final before = [..._badge.writes];

    await _account.syncs(general);

    expect(_badge.writes, [...before, 1]);
  });
}

void _roomOpenTests() {
  test('opening a room writes the count of the other rooms', () {
    _account.joined(_general).notificationCount = 1;
    _account.joined(_random).notificationCount = 1;

    _onIphone().roomOpened(_general);

    expect(_badge.writes, [1]);
  });

  test('opening the only unread room removes the badge', () {
    _account.joined(_general).notificationCount = 1;

    _onIphone().roomOpened(_general);

    expect(_badge.writes, [removed]);
  });

  test('a sync after opening a room writes nothing when the count is the '
      'one already on the icon', () async {
    final general = _account.joined(_general)..notificationCount = 1;
    _account.joined(_random).notificationCount = 1;
    _onIphone().roomOpened(_general);

    general.notificationCount = 0;
    await _account.syncs(general);

    expect(_badge.writes, [1]);
  });
}

void _threadsOffTests() {
  setUp(() => AppConfig.threadsEnabled = false);

  test('a sync writes nothing; opening a room still writes', () async {
    final general = _account.joined(_general)..notificationCount = 1;
    _account.joined(_random).notificationCount = 1;
    final iphone = _onIphone();

    await _account.syncs(general);
    expect(_badge.writes, isEmpty);

    iphone.roomOpened(_general);
    expect(_badge.writes, [1]);
  });

  test('going to the background writes nothing; opening a room still '
      'writes', () async {
    _account.joined(_general).notificationCount = 1;
    final iphone = _onIphone();

    await appGoesToBackground();
    expect(_badge.writes, isEmpty);

    iphone.roomOpened(_random);
    expect(_badge.writes, [1]);
  });

  test('coming back to the foreground writes nothing; opening a room still '
      'writes', () async {
    _account.joined(_general).notificationCount = 1;
    final iphone = _onIphone();
    await appGoesToBackground();

    await appInForeground();
    expect(_badge.writes, isEmpty);

    iphone.roomOpened(_random);
    expect(_badge.writes, [1]);
  });

  test('a follow lookup that finishes writes nothing', () async {
    _account.joined(_general);
    _account.answerLater();
    _onIphone();
    _account.threadGets(_generalThread, _repliesOnly);

    await _account.answersUserWroteIn(_generalThread);

    expect(_badge.writes, isEmpty);
  });

  test('opening a room twice writes twice', () {
    _account.joined(_general).notificationCount = 1;
    _account.joined(_random).notificationCount = 1;

    _onIphone()
      ..roomOpened(_general)
      ..roomOpened(_general);

    expect(_badge.writes, [1, 1]);
  });
}

Future<void> _notOnIosTest() async {
  final general = _account.joined(_general)..notificationCount = 1;
  _account.joined(_random).notificationCount = 1;
  final android = _updater = IconBadgeUpdater(
    client: _account,
    badge: _badge,
    onIos: false,
  );

  await _account.syncs(general);
  await appGoesToBackground();
  await appInForeground();
  android.roomOpened(_general);

  expect(_badge.writes, isEmpty);
}

const _general = RoomId('!general:example.com');
const _random = RoomId('!random:example.com');
const _generalThread = ThreadRef('!general:example.com', r'$root');

/// Three replies, none of them mentions the user.
const _repliesOnly = (notificationCount: 3, highlightCount: 0);

/// Three replies, one of them mentions the user.
const _withMention = (notificationCount: 3, highlightCount: 1);
