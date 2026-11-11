import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/datasource_impl/thread/thread_prefs_datasource.provider.dart';
import 'package:twake_chat/data/datasource_impl/thread/thread_prefs_datasource_impl.dart';
import 'package:twake_chat/domain/model/thread/thread_prefs.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

import 'thread_account.dart';

/// THR-M-07, THR-M-08 and the review of P2: the list of choices of
/// `app.twake.chat.thread_prefs` is shared with the web, which may change it
/// at any time. What the device holds may be old (a catch-up sync not
/// handled yet), unreadable, or the echo of an earlier write: a choice is
/// written over the list the server holds right then, so it never erases a
/// choice made elsewhere. Saves of one account run one at a time, wherever
/// they come from; another account is not held by them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _server = RecordingHomeserver();
  });

  group('the list of the server is the base of a choice', _serverBaseTests);
  group('three quick choices on a slow network', _slowNetworkTests);
  group('another account on the same device', _otherAccountTests);
  group('saves run one at a time per account', _serializedTests);
  group('the user logs out while a choice is saved', _logOutMidSaveTests);
  group('the write of the list fails', _failedWriteTests);
}

late RecordingHomeserver _server;

const _planningThread = ThreadRef(teamRoomId, r'$planning');
const _otherUser = '@other:example.org';

/// The account of [threadOwner] on [server], opened from the device.
Future<ThreadAccount> _startedAccount([RecordingHomeserver? server]) async {
  final account = ThreadAccount(server ?? _server);
  await account.start();
  return account;
}

/// The choices of `app.twake.chat.thread_prefs`, as the device stored them.
Map<String, BasicEvent> _storedOnDevice(List<Map<String, Object?>> entries) => {
  'app.twake.chat.thread_prefs': BasicEvent(
    type: 'app.twake.chat.thread_prefs',
    content: {'threads': entries},
  ),
};

/// The app opens again on a device that fails to read its stored account
/// data, and the user makes the choice of [body]. The errors the SDK leaves
/// unhandled about that read are not the subject (see
/// thread_prefs_badge_test.dart); a failure of [body] is.
Future<void> _onUnreadableDevice(_Choice body) async {
  final account = ThreadAccount(_server, accountDataUnreadable: true);
  final done = Completer<Object?>();
  runZonedGuarded(() async {
    try {
      await account.openAsTheApp();
      await body(ThreadPrefsDatasourceImpl(account));
      done.complete();
    } catch (failure) {
      done.complete(failure);
    }
  }, (_, _) {});
  final failure = await done.future;
  if (failure != null) throw failure;
}

void _serverBaseTests() {
  test('the app started from the device, its catch-up sync not handled yet: '
      'a thread muted on the web meanwhile stays muted', () async {
    _server.storeThreadPrefs([
      prefEntry(releaseThread, WirePref.mute),
      prefEntry(lunchThread, WirePref.follow),
    ]);
    final account = ThreadAccount(
      _server,
      storedAccountData: _storedOnDevice([
        prefEntry(lunchThread, WirePref.follow),
      ]),
    );
    await account.startBeforeCatchUp();

    await ThreadPrefsDatasourceImpl(
      account,
    ).saveThreadPref(lunchThread, ThreadPref.unfollow);

    expect(_server.callsTo(threadPrefsWrite).last.body, {
      'threads': [
        prefEntry(lunchThread, WirePref.unfollow),
        prefEntry(releaseThread, WirePref.mute),
      ],
    });
  });

  test('an account that never synced on this device: the choice is saved, '
      'the choices of the web kept', () async {
    await _followLunchOverWebMute(
      (follow) => follow(ThreadPrefsDatasourceImpl(ThreadAccount(_server))),
    );
  });

  test('the account data of the device cannot be read: the first choice '
      'does not erase the other choices of the account', () async {
    await _followLunchOverWebMute(_onUnreadableDevice);
  });
}

typedef _Choice = Future<void> Function(ThreadPrefsDatasourceImpl choices);

/// The web muted the release thread; the user follows the lunch thread
/// through what [open] opens: the account keeps both.
Future<void> _followLunchOverWebMute(
  Future<void> Function(_Choice follow) open,
) async {
  _server.storeThreadPrefs([prefEntry(releaseThread, WirePref.mute)]);

  await open(
    (choices) => choices.saveThreadPref(lunchThread, ThreadPref.follow),
  );

  expect(_server.threadPrefsOf(), [
    prefEntry(lunchThread, WirePref.follow),
    prefEntry(releaseThread, WirePref.mute),
  ]);
}

WirePref _wire(ThreadPref pref) => WirePref.values.byName(pref.name);

/// The user makes the first choice, then two more while the server is slow
/// to store the second; meanwhile the sync echoes the first.
Future<void> _threeQuickChoices(
  ThreadAccount account,
  List<(ThreadRef, ThreadPref)> choices,
) async {
  final datasource = ThreadPrefsDatasourceImpl(account);
  _server.hold(threadPrefsWrite);
  final saves = [
    for (final (thread, pref) in choices)
      datasource.saveThreadPref(thread, pref),
  ];
  await pumpEventQueue();
  // The first list is stored; the second waits.
  _server
    ..release(threadPrefsWrite)
    ..hold(threadPrefsWrite);
  await pumpEventQueue();
  await account.echoOfWrite(0);
  _server.release(threadPrefsWrite);
  await Future.wait(saves);
}

void _slowNetworkTests() {
  late ThreadAccount account;

  setUp(() async {
    account = await _startedAccount();
  });

  test('the echo of the first arriving meanwhile: the account keeps all '
      'three', () async {
    await _threeQuickChoices(account, [
      (lunchThread, ThreadPref.mute),
      (releaseThread, ThreadPref.unfollow),
      (_planningThread, ThreadPref.follow),
    ]);

    expect(
      _server.threadPrefsOf(),
      unorderedEquals([
        prefEntry(lunchThread, WirePref.mute),
        prefEntry(releaseThread, WirePref.unfollow),
        prefEntry(_planningThread, WirePref.follow),
      ]),
    );
  });

  /// Else the thread stays silent on the server while no client shows it
  /// muted, or the other way round.
  for (final (last, what) in [
    (ThreadPref.follow, 'unmuted'),
    (ThreadPref.mute, 'muted again'),
  ]) {
    test('muted, then $what: the thread is silenced on the server only if '
        'the account says it is muted', () async {
      await _threeQuickChoices(account, [
        (lunchThread, ThreadPref.mute),
        (releaseThread, ThreadPref.unfollow),
        (lunchThread, last),
      ]);

      final finalList = _server.threadPrefsOf();
      expect(finalList, contains(equals(prefEntry(lunchThread, _wire(last)))));
      expect(
        _server.hasPushRule(lunchThread),
        contains(
          equals(prefEntry(lunchThread, WirePref.mute)),
        ).matches(finalList, {}),
      );
    });
  }
}

void _otherAccountTests() {
  late ThreadAccount account;
  late ThreadPrefsDatasourceImpl datasource;

  setUp(() async {
    account = await _startedAccount();
    datasource = ThreadPrefsDatasourceImpl(account);
    await datasource.saveThreadPref(lunchThread, ThreadPref.mute);
    await account.logOutThenLogIn(_otherUser);
  });

  test(
    'the first choice of the next account writes only its own choices',
    () async {
      await datasource.saveThreadPref(releaseThread, ThreadPref.unfollow);

      expect(_server.threadPrefsOf(_otherUser), [
        prefEntry(releaseThread, WirePref.unfollow),
      ]);
    },
  );

  test('the next account shows none of the choices of the one before', () {
    expect(account.threadUnread.prefOf(lunchThread), isNull);
  });

  test('the menu of the next account shows the thread not muted', () async {
    final shown = await datasource.watchThread(lunchThread).first;

    expect(shown.follow.isMuted, isFalse);
  });
}

void _serializedTests() {
  test('two choices from two screens on a slow network: the account keeps '
      'both', () async {
    final account = await _startedAccount();
    final container = ProviderContainer.test(
      overrides: [activeMatrixClientProvider.overrideWithValue(account)],
    );
    _server.hold(threadPrefsWrite);

    final mute = container
        .read(threadPrefsDatasourceProvider)
        .saveThreadPref(lunchThread, ThreadPref.mute);
    // The first screen is gone: nothing listens to the provider any more.
    await pumpEventQueue();
    final unfollow = container
        .read(threadPrefsDatasourceProvider)
        .saveThreadPref(releaseThread, ThreadPref.unfollow);
    await pumpEventQueue();
    _server.release(threadPrefsWrite);
    await Future.wait([mute, unfollow]);

    expect(
      _server.threadPrefsOf(),
      unorderedEquals([
        prefEntry(lunchThread, WirePref.mute),
        prefEntry(releaseThread, WirePref.unfollow),
      ]),
    );
  });

  test(
    'a slow save of one account does not hold the choice of another',
    () async {
      final slow = ThreadPrefsDatasourceImpl(await _startedAccount());
      _server.hold(threadPrefsWrite);
      unawaited(slow.saveThreadPref(lunchThread, ThreadPref.mute));
      await pumpEventQueue();
      final otherServer = RecordingHomeserver();
      final other = await _startedAccount(otherServer);

      await ThreadPrefsDatasourceImpl(other)
          .saveThreadPref(releaseThread, ThreadPref.unfollow)
          .timeout(const Duration(seconds: 2));

      expect(otherServer.threadPrefsOf(), [
        prefEntry(releaseThread, WirePref.unfollow),
      ]);
      _server.release(threadPrefsWrite);
    },
  );
}

/// The user mutes the lunch thread on a network that holds [held]; meanwhile
/// they log out and [_otherUser] logs in on the same device, then the
/// server answers. Gives the next account; its failure is not the subject.
Future<ThreadAccount> _muteThenLogOut(ServerRoute held) async {
  final account = await _startedAccount();
  _server.hold(held);
  final save = ThreadPrefsDatasourceImpl(
    account,
  ).saveThreadPref(lunchThread, ThreadPref.mute).then((_) {}, onError: (_) {});
  await pumpEventQueue();
  await account.logOutThenLogIn(_otherUser);
  _server.release(held);
  await save;
  return account;
}

void _logOutMidSaveTests() {
  test('the list was being written: the next account shows none of the '
      'choice', () async {
    final next = await _muteThenLogOut(threadPrefsWrite);

    expect(next.threadUnread.prefOf(lunchThread), isNull);
    final shown = await ThreadPrefsDatasourceImpl(
      next,
    ).watchThread(lunchThread).first;
    expect(shown.follow.isMuted, isFalse);
  });

  test('the thread was being silenced: the choice is not written in the '
      'account of the next user', () async {
    await _muteThenLogOut(threadRuleWrite);

    expect(_server.threadPrefsOf(_otherUser), isNull);
  });

  test('a save of the user before, stuck on the network, does not hold the '
      'first choice of the next user', () async {
    final account = await _startedAccount();
    final datasource = ThreadPrefsDatasourceImpl(account);
    _server.hold(threadPrefsWrite);
    unawaited(datasource.saveThreadPref(lunchThread, ThreadPref.mute));
    await pumpEventQueue();
    await account.logOutThenLogIn(_otherUser);

    await datasource
        .saveThreadPref(releaseThread, ThreadPref.unfollow)
        .timeout(const Duration(seconds: 2));

    expect(_server.threadPrefsOf(_otherUser), [
      prefEntry(releaseThread, WirePref.unfollow),
    ]);
    _server.release(threadPrefsWrite);
  });
}

/// The lunch thread is [first]; the user then makes it [then], and the
/// server handles the write of the list as [writeFails] says.
Future<void> _changeLunch(
  ThreadPref first,
  ThreadPref then,
  void Function() writeFails,
) async {
  final datasource = ThreadPrefsDatasourceImpl(await _startedAccount());
  await datasource.saveThreadPref(lunchThread, first);
  writeFails();
  await datasource
      .saveThreadPref(lunchThread, then)
      .then((_) {}, onError: (_) {});
}

void _failedWriteTests() {
  /// The server stored the list; only its answer was lost. Restoring the
  /// rule blindly leaves the thread silenced while every client shows it
  /// not muted, or the other way round.
  for (final (first, then) in [
    (ThreadPref.mute, ThreadPref.follow),
    (ThreadPref.follow, ThreadPref.mute),
  ]) {
    test('${first.name}, then ${then.name}, the answer lost on a flaky '
        'network: the thread is silenced on the server only if its list says '
        'muted', () async {
      await _changeLunch(
        first,
        then,
        () => _server.loseResponses(threadPrefsWrite),
      );

      expect(
        _server.threadPrefsOf(),
        contains(equals(prefEntry(lunchThread, _wire(then)))),
      );
      expect(_server.hasPushRule(lunchThread), then == ThreadPref.mute);
    });
  }

  test('muted, then unmuted, the server refuses the list: the thread stays '
      'silenced, as its list says', () async {
    await _changeLunch(
      ThreadPref.mute,
      ThreadPref.follow,
      () => _server.fail(threadPrefsWrite),
    );

    expect(_server.threadPrefsOf(), [prefEntry(lunchThread, WirePref.mute)]);
    expect(_server.hasPushRule(lunchThread), isTrue);
  });
}
