import 'dart:async';
import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/datasource_impl/thread/thread_prefs_datasource_impl.dart';
import 'package:twake_chat/domain/model/thread/thread_prefs.dart';
import 'package:twake_chat/domain/model/thread/thread_status.dart';

import 'thread_account.dart';

/// THR-M-07 and THR-M-08: what the menu of a thread shows, read from the
/// account. Following = taking part (P1) unless the user chose; the choice
/// and the resolved state may come from the web at any time, and show
/// without reopening the thread.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _account = ThreadAccount(RecordingHomeserver());
    _datasource = ThreadPrefsDatasourceImpl(_account);
    await _account.receiveRoomState([_memberLevels]);
  });

  tearDown(() async {
    await _watching?.cancel();
    _watching = null;
    _seen.clear();
  });

  group('following', _followTests);
  group('a change made on the web', _liveTests);
  group('who may resolve', _permissionTests);
  group('the server is asked about taking part', _lookupTests);
  group('the choices of the account', _choicesReadTests);
  group('a choice saved here, before the sync echoes it', _readAfterWriteTests);

  /// Else the menu stays disabled without a word: it tells the failure.
  test('no account: watching fails, so the menu can say so', () async {
    const datasource = ThreadPrefsDatasourceImpl(null);
    final failures = <Object>[];

    await datasource
        .watchThread(lunchThread)
        .handleError(failures.add)
        .drain<void>();

    expect(failures, isNotEmpty);
  });
}

late ThreadAccount _account;

/// The one the app holds for the account: the menu watches and saves
/// through it.
late ThreadPrefsDatasourceImpl _datasource;

/// Every status the screen was given, in order; the last one is on screen.
final List<ThreadStatus> _seen = [];
StreamSubscription<ThreadStatus>? _watching;

const _notFollowed = ThreadFollow(isFollowing: false, isMuted: false);
const _followed = ThreadFollow(isFollowing: true, isMuted: false);
const _muted = ThreadFollow(isFollowing: true, isMuted: true);

/// The user is a plain member: states need 50, the thread state 0.
final _memberLevels = powerLevels({
  'users': {threadOwner: 0},
  'state_default': 50,
  'events': {'app.twake.chat.thread_resolved': 0},
});

/// Watches the thread as the screen does, then gives the first status.
Future<ThreadStatus> _shown() async {
  _watching = _datasource.watchThread(lunchThread).listen(_seen.add);
  await _settle(() => _seen.isNotEmpty);
  return _seen.first;
}

/// Lets the stream run until [done], 100 turns of the event queue at most.
Future<void> _settle(bool Function() done) async {
  for (var turn = 0; turn < 100 && !done(); turn++) {
    await pumpEventQueue();
  }
}

Future<void> _choiceOnTheWeb(WirePref pref) =>
    _account.receiveThreadPrefs([prefEntry(lunchThread, pref)]);

/// What is on screen ends up matching [matcher].
Future<void> _expectShows(Matcher matcher) async {
  await _settle(() => matcher.matches(_seen.last, {}));
  expect(_seen.last, matcher);
}

Matcher _follow(ThreadFollow follow) =>
    isA<ThreadStatus>().having((s) => s.follow, 'follow', follow);

Matcher _resolved(Matcher isResolved) =>
    isA<ThreadStatus>().having((s) => s.isResolved, 'isResolved', isResolved);

void _followTests() {
  test('a thread the user never wrote in is not followed', () async {
    expect(await _shown(), _follow(_notFollowed));
  });

  test('a thread the user wrote in is followed', () async {
    _account.threadUnread.markFollowed(lunchThread);

    expect(await _shown(), _follow(_followed));
  });

  test(
    'a thread the user wrote in, then unfollowed, is not followed',
    () async {
      _account.threadUnread.markFollowed(lunchThread);
      await _choiceOnTheWeb(WirePref.unfollow);

      expect(await _shown(), _follow(_notFollowed));
    },
  );

  test('a thread followed without writing in it is followed', () async {
    await _choiceOnTheWeb(WirePref.follow);

    expect(await _shown(), _follow(_followed));
  });

  test('a muted thread is followed and muted', () async {
    await _choiceOnTheWeb(WirePref.mute);

    expect(await _shown(), _follow(_muted));
  });

  test('a choice for another thread does not apply to this one', () async {
    await _account.receiveThreadPrefs([
      prefEntry(releaseThread, WirePref.mute),
    ]);

    expect(await _shown(), _follow(_notFollowed));
  });
}

void _liveTests() {
  test('muted on the web: shows muted, the thread still open', () async {
    expect(await _shown(), _follow(_notFollowed));

    await _choiceOnTheWeb(WirePref.mute);

    await _expectShows(_follow(_muted));
  });

  test('resolved on the web: shows resolved, the thread still open', () async {
    expect(await _shown(), _resolved(isFalse));

    await _account.receiveRoomState([resolvedState(lunchThread)]);

    await _expectShows(_resolved(isTrue));
  });

  test('resolved by another client during a live sync (the state in the '
      'timeline of the sync): shows resolved', () async {
    expect(await _shown(), _resolved(isFalse));

    await _account.receiveRoomState([
      resolvedState(lunchThread),
    ], section: RoomSection.timeline);

    await _expectShows(_resolved(isTrue));
  });

  test('reopened on the web: no longer resolved', () async {
    await _account.receiveRoomState([resolvedState(lunchThread)]);
    expect(await _shown(), _resolved(isTrue));

    await _account.receiveRoomState([reopenedState(lunchThread)]);

    await _expectShows(_resolved(isFalse));
  });
}

void _permissionTests() {
  test('a member, when the thread state is open to members', () async {
    expect((await _shown()).canResolve, isTrue);
  });

  test('not a member who may only send messages', () async {
    await _account.receiveRoomState([
      powerLevels({
        'users': {threadOwner: 0},
        'events_default': 0,
        'state_default': 50,
      }),
    ]);

    expect((await _shown()).canResolve, isFalse);
  });
}

void _lookupTests() {
  Iterable<ServerCall> lookups() => _account.server.callsTo(lunchRootLookup);

  test('when the user made no choice', () async {
    await _shown();
    await _settle(() => lookups().isNotEmpty);

    expect(lookups(), isNotEmpty);
  });

  for (final pref in WirePref.values) {
    test(
      'never when the user chose « ${pref.name} »: the choice decides',
      () async {
        await _choiceOnTheWeb(pref);

        await _shown();
        await _settle(() => lookups().isNotEmpty);

        expect(lookups(), isEmpty);
      },
    );
  }
}

/// The content of `app.twake.chat.thread_prefs` (up to 500 choices), which
/// counts the times its list is read.
class _CountedChoices extends MapView<String, Object?> {
  _CountedChoices(List<Map<String, Object?>> entries)
    : super({'threads': entries});

  int reads = 0;

  @override
  Object? operator [](Object? key) {
    if (key == 'threads') reads++;
    return super[key];
  }
}

/// THR-M-07, review of P2: a busy room syncs often, and the list of choices
/// does not change with it; it is read again only when the account data is
/// replaced.
void _choicesReadTests() {
  test('a sync of the room does not read the list of choices again', () async {
    final choices = _CountedChoices([prefEntry(lunchThread, WirePref.mute)]);
    _account.accountData['app.twake.chat.thread_prefs'] = BasicEvent(
      type: 'app.twake.chat.thread_prefs',
      content: choices,
    );
    expect(await _shown(), _follow(_muted));
    final readsOnShow = choices.reads;

    for (var sync = 0; sync < 3; sync++) {
      await _account.receiveRoomState([
        _memberLevels,
      ], section: RoomSection.timeline);
    }
    await _settle(() => false);

    expect(choices.reads, readsOnShow);
  });
}

/// What is on screen once everything ran.
Future<ThreadStatus> _settled() async {
  await _settle(() => false);
  return _seen.last;
}

/// The thread on screen, the user mutes it then unmutes it, before any
/// echo.
Future<void> _muteThenUnmuteHere() async {
  await _shown();
  await _datasource.saveThreadPref(lunchThread, ThreadPref.mute);
  await _datasource.saveThreadPref(lunchThread, ThreadPref.follow);
}

/// THR-M-07 and the review of P2: a choice saved here shows at once, as the
/// web shows it (`#prefsHere` of MatrixAccountPrefs.ts) until the sync
/// echoes the list it wrote; the echo of an earlier write never brings an
/// older choice back.
void _readAfterWriteTests() {
  test('a thread muted here shows muted at once', () async {
    expect(await _shown(), _follow(_notFollowed));

    await _datasource.saveThreadPref(lunchThread, ThreadPref.mute);

    await _expectShows(_follow(_muted));
  });

  test('muted then unmuted before the echoes: the echo of the mute does not '
      'show it muted again', () async {
    await _muteThenUnmuteHere();
    await _settled();
    final shownBeforeEcho = _seen.length;

    await _account.echoOfWrite(0);

    expect(await _settled(), _follow(_followed));
    expect(_seen.skip(shownBeforeEcho), everyElement(_follow(_followed)));
  });

  test('then the echo of the unmute: still followed, not muted', () async {
    await _muteThenUnmuteHere();
    await _account.echoOfWrite(0);

    await _account.echoOfWrite(1);

    expect(await _settled(), _follow(_followed));
  });

  /// The choice shown here gives way once the server echoed it.
  test('once its echo came, a choice made on the web shows', () async {
    await _shown();
    await _datasource.saveThreadPref(lunchThread, ThreadPref.mute);
    await _account.echoOfWrite(0);

    await _account.webWrites([prefEntry(lunchThread, WirePref.unfollow)]);

    await _expectShows(_follow(_notFollowed));
  });
}
