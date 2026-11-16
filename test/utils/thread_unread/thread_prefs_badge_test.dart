import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/datasource_impl/thread/thread_prefs_datasource_impl.dart';
import 'package:twake_chat/domain/model/thread/thread_prefs.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/model/thread/thread_unread.dart';
import 'package:twake_chat/domain/model/thread/thread_unread_state.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

import '../../data/datasource_impl/thread/thread_account.dart';

/// THR-M-06 and THR-M-07, P2: the badge of a room counts the unread replies
/// of the threads followed and not muted, plus the mentions of any thread
/// not muted (web `readState.ts`). The explicit choice of
/// `app.twake.chat.thread_prefs` wins over taking part; a muted thread stays
/// followed but counts nothing, mentions included. A choice made on the web
/// applies at the next sync, without a restart.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _account = ThreadAccount(RecordingHomeserver());
    _room = Room(id: teamRoomId, client: _account);
  });

  group('the explicit choice wins over taking part', _choiceTests);
  group('a muted thread', _mutedTests);
  group('a choice made on the web', _liveTests);
  group('an explicit choice decides alone', _noLookupTests);
  group(
    'a choice saved on this device, before the sync echoes it',
    _savedHereTests,
  );
  group('at startup, before the first sync', _startupTests);
  group(
    'at startup, the choices stored on the device cannot be read',
    _unreadableChoicesTests,
  );
}

late ThreadAccount _account;
late Room _room;

ThreadUnreadStore get _store => _account.threadUnread;

/// The lunch thread has 4 unread replies, 1 of them a mention.
void _lunchUnread() => _store.apply(
  const SyncThreadUpdate(
    counts: {
      teamRoomId: {r'$lunch': (notificationCount: 4, highlightCount: 1)},
    },
    leftRoomIds: [],
  ),
);

Iterable<ServerCall> get _lookups => _account.server.callsTo(lunchRootLookup);

Future<void> _choose(WirePref pref, {ThreadRef thread = lunchThread}) =>
    _account.receiveThreadPrefs([prefEntry(thread, pref)]);

void _choiceTests() {
  test('a thread the user wrote in, then unfollowed, counts its mentions '
      'only', () async {
    _store.markFollowed(lunchThread);
    await _choose(WirePref.unfollow);
    _lunchUnread();

    expect(_store.badgeOf(_room), 1);
    expect(_store.isFollowed(lunchThread), isFalse);
  });

  test(
    'an unfollowed thread stays so when the user writes in it again',
    () async {
      await _choose(WirePref.unfollow);
      _store.markFollowed(lunchThread);
      _lunchUnread();

      expect(_store.isFollowed(lunchThread), isFalse);
      expect(_store.badgeOf(_room), 1);
    },
  );

  test('a thread followed without writing in it counts every unread '
      'reply', () async {
    await _choose(WirePref.follow);
    _lunchUnread();

    expect(_store.isFollowed(lunchThread), isTrue);
    expect(_store.badgeOf(_room), 4);
  });

  test('a choice for another thread leaves this one to taking part', () async {
    _store.markFollowed(lunchThread);
    await _choose(WirePref.unfollow, thread: releaseThread);
    _lunchUnread();

    expect(_store.badgeOf(_room), 4);
  });
}

void _mutedTests() {
  setUp(() async {
    await _choose(WirePref.mute);
    _lunchUnread();
  });

  test('is still followed', () {
    expect(_store.isFollowed(lunchThread), isTrue);
    expect(_store.isMuted(lunchThread), isTrue);
  });

  test('adds nothing to the badge, its mentions neither', () {
    expect(_store.badgeOf(_room), 0);
    expect(_room.unreadBadgeCount, 0);
  });

  test('adds no mention to the room', () {
    expect(_room.highlightCountWithThreads, 0);
  });

  test('does not make the room unread', () {
    expect(_room.isUnreadWithThreads, isFalse);
  });

  test('is not the thread the banner of new replies opens', () {
    expect(
      unreadThreadBannerTarget(
        mainNotificationCount: 0,
        threads: _store.threadsOf(_room),
      ),
      isNull,
    );
  });

  test('a thread not chosen for is not muted', () {
    expect(_store.isMuted(releaseThread), isFalse);
  });

  /// Web `readThreadStates.ts`: `isMuted ? 0 : …`. The card of the thread
  /// shows the count the store gives (`Chat.threadUnreadCount`).
  test('its card shows no unread count', () {
    expect(_store.unreadCount(lunchThread), 0);
  });

  test('unmuted, its card shows its unread replies again', () async {
    await _choose(WirePref.follow);

    expect(_store.unreadCount(lunchThread), 4);
  });
}

void _liveTests() {
  test('muted on the web: the badge drops at the next sync', () async {
    _store.markFollowed(lunchThread);
    _lunchUnread();
    expect(_store.badgeOf(_room), 4);

    await _choose(WirePref.mute);

    expect(_store.badgeOf(_room), 0);
  });

  test('unmuted on the web: the badge comes back at the next sync', () async {
    await _choose(WirePref.mute);
    _lunchUnread();

    await _choose(WirePref.follow);

    expect(_store.badgeOf(_room), 4);
  });

  test('a choice from the web tells the listeners, so the list of rooms '
      'redraws', () async {
    _lunchUnread();
    var told = 0;
    _store.addListener(() => told++);

    await _choose(WirePref.follow);

    expect(told, isPositive);
  });
}

/// Whether the user took part is asked of the server only when no choice
/// decides (THR-M-07: the choice wins over taking part).
void _noLookupTests() {
  test('no choice: new replies make the server tell whether the user took '
      'part', () async {
    _lunchUnread();
    await pumpEventQueue();

    expect(_lookups, isNotEmpty);
  });

  for (final pref in WirePref.values) {
    test('« ${pref.name} »: new replies ask the server nothing', () async {
      await _choose(pref);

      _lunchUnread();
      await pumpEventQueue();

      expect(_lookups, isEmpty);
    });

    test('« ${pref.name} »: the room waits on no lookup, its notifications '
        'may be cleared', () async {
      await _choose(pref);

      _lunchUnread();

      expect(_store.hasPendingFollowLookup(_room), isFalse);
    });
  }
}

/// The app is closed with 4 unread replies in the lunch thread, which the
/// user had written in; [_account] is that session.
Future<void> _lastSessionSaved() async {
  _store.markFollowed(lunchThread);
  _lunchUnread();
  await Future<void>.delayed(Duration.zero);
  await pumpEventQueue();
}

/// The app opens again: the counters saved by the last session are
/// restored, then the session loads [storedChoices] from the device. The
/// server answers no sync.
Future<ThreadAccount> _reopen(List<Map<String, Object?>> storedChoices) async {
  final account = ThreadAccount(
    RecordingHomeserver(),
    storedAccountData: {
      'app.twake.chat.thread_prefs': BasicEvent(
        type: 'app.twake.chat.thread_prefs',
        content: {'threads': storedChoices},
      ),
    },
  );
  await pumpEventQueue();
  return account;
}

int _badgeIn(ThreadAccount account) =>
    account.threadUnread.badgeOf(Room(id: teamRoomId, client: account));

void _startupTests() {
  setUp(_lastSessionSaved);

  test('no choice stored: the saved badge shows', () async {
    final account = await _reopen(const []);

    await account.start();

    expect(_badgeIn(account), 4);
  });

  test('a thread muted on the device counts nothing, without waiting for '
      'a sync', () async {
    final account = await _reopen([prefEntry(lunchThread, WirePref.mute)]);

    await account.start();

    expect(_badgeIn(account), 0);
  });

  test('the choices stored on the device tell the listeners, so the list '
      'of rooms redraws', () async {
    final account = await _reopen([prefEntry(lunchThread, WirePref.mute)]);
    var told = 0;
    account.threadUnread.addListener(() => told++);

    await account.start();
    await pumpEventQueue();

    expect(told, isPositive);
  });
}

/// Errors nobody handled while [body] ran, and the turns of the event queue
/// after it.
Future<List<Object>> _uncaughtWhile(Future<void> Function() body) {
  final errors = <Object>[];
  final done = Completer<List<Object>>();
  runZonedGuarded(() async {
    try {
      await body();
      await pumpEventQueue();
    } finally {
      done.complete(errors);
    }
  }, (error, _) => errors.add(error));
  return done.future;
}

/// The app opens again, as `ClientManager` opens it, on a device that fails
/// to read the stored account data.
Future<(ThreadAccount, List<Object>)> _openOnUnreadableDevice() async {
  late ThreadAccount account;
  final errors = await _uncaughtWhile(() async {
    account = ThreadAccount(RecordingHomeserver(), accountDataUnreadable: true);
    await pumpEventQueue();
    await account.openAsTheApp();
  });
  return (account, errors);
}

void _unreadableChoicesTests() {
  setUp(_lastSessionSaved);

  /// The SDK alone already leaves the failed read unhandled (its first sync
  /// awaits it only after the network): the threads add none of their own.
  test('the threads add no unhandled error of their own', () async {
    final sdkAlone = await _uncaughtWhile(openSdkClientOnUnreadableDevice);

    final (_, errors) = await _openOnUnreadableDevice();

    expect(errors.length, lessThanOrEqualTo(sdkAlone.length));
  });

  test('the saved badge still shows', () async {
    final (account, _) = await _openOnUnreadableDevice();

    expect(_badgeIn(account), 4);
  });
}

/// THR-M-07 and the review of P2: what the user just chose here applies at
/// once to the badge and to the notifications, as on the web (`#prefsHere`
/// of MatrixAccountPrefs.ts), and the echo of an earlier write never brings
/// an older choice back.
void _savedHereTests() {
  late ThreadPrefsDatasourceImpl choices;

  setUp(() async {
    await _account.start();
    choices = ThreadPrefsDatasourceImpl(_account);
    _store.markFollowed(lunchThread);
    _lunchUnread();
  });

  test('muting a followed thread takes its replies off the badge', () async {
    expect(_store.badgeOf(_room), 4);

    await choices.saveThreadPref(lunchThread, ThreadPref.mute);

    expect(_store.badgeOf(_room), 0);
  });

  test('the list of rooms is told, so it redraws', () async {
    var told = 0;
    _store.addListener(() => told++);

    await choices.saveThreadPref(lunchThread, ThreadPref.mute);

    expect(told, isPositive);
  });

  test('the notifications read the choice', () async {
    await choices.saveThreadPref(lunchThread, ThreadPref.mute);

    expect(_store.prefOf(lunchThread), ThreadPref.mute);
  });

  test('muted then unmuted: the echo of the mute does not silence the thread '
      'again', () async {
    await choices.saveThreadPref(lunchThread, ThreadPref.mute);
    await choices.saveThreadPref(lunchThread, ThreadPref.follow);

    await _account.echoOfWrite(0);

    expect(_store.prefOf(lunchThread), ThreadPref.follow);
    expect(_store.badgeOf(_room), 4);
  });
}
