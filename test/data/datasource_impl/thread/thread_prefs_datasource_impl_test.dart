import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/datasource_impl/thread/thread_prefs_datasource_impl.dart';
import 'package:twake_chat/domain/exception/thread/thread_change_exception.dart';
import 'package:twake_chat/domain/model/thread/thread_prefs.dart';

import 'thread_account.dart';

/// THR-M-07, THR-M-08, THR-M-09 and spec § 4: what the homeserver receives
/// when the user changes a thread, byte for byte the conventions of the web
/// (twake-space-chat `MatrixAccountPrefs.saveThreadPref`, D56, D60), so a
/// choice made on one client applies on the other.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _server = RecordingHomeserver();
    _account = ThreadAccount(_server);
    await _account.start();
    _datasource = ThreadPrefsDatasourceImpl(_account);
  });

  group('muting a thread', _muteTests);
  group('any other choice', _otherChoiceTests);
  group('the shared list of choices', _sharedListTests);
  group('a choice that fails', _failureTests);
  group('two choices on a slow network', _concurrentTests);
  group('resolving a thread', _resolveTests);
}

late RecordingHomeserver _server;
late ThreadAccount _account;
late ThreadPrefsDatasourceImpl _datasource;

const _muteRule = ServerRoute.put(
  r'pushrules/global/override/app.twake.chat.thread.$lunch',
);
const _deleteRule = ServerRoute.delete(
  r'pushrules/global/override/app.twake.chat.thread.$lunch',
);
const _anyRulePut = ServerRoute.put('pushrules/');
const _prefs = threadPrefsWrite;
const _resolved = ServerRoute.put(
  r'rooms/!team:example.org/state/app.twake.chat.thread_resolved/$lunch',
);

Object? _lastBody(ServerRoute route) => _server.callsTo(route).last.body;

int _indexOf(ServerRoute route) =>
    _server.calls.indexWhere((call) => call.hits(route));

Future<void> _expectChangeFails(Future<void> change) =>
    expectLater(change, throwsA(isA<ThreadChangeFailedException>()));

void _muteTests() {
  test('adds the override push rule of the web, without any action', () async {
    await _datasource.saveThreadPref(lunchThread, ThreadPref.mute);

    expect(_lastBody(_muteRule), {
      'actions': <Object?>[],
      'conditions': [
        {'kind': 'event_match', 'key': 'room_id', 'pattern': teamRoomId},
        {
          'kind': 'event_property_is',
          'key': r'content.m\.relates_to.rel_type',
          'value': 'm.thread',
        },
        {
          'kind': 'event_property_is',
          'key': r'content.m\.relates_to.event_id',
          'value': lunchThread.rootEventId,
        },
      ],
    });
  });

  test('writes the choice in the shared account data', () async {
    await _datasource.saveThreadPref(lunchThread, ThreadPref.mute);

    expect(_lastBody(_prefs), {
      'threads': [prefEntry(lunchThread, WirePref.mute)],
    });
  });

  test('silences the server before telling the other clients', () async {
    await _datasource.saveThreadPref(lunchThread, ThreadPref.mute);

    expect(_indexOf(_muteRule), lessThan(_indexOf(_prefs)));
  });
}

void _otherChoiceTests() {
  for (final (pref, wire) in [
    (ThreadPref.follow, WirePref.follow),
    (ThreadPref.unfollow, WirePref.unfollow),
  ]) {
    test('${wire.name} removes the push rule of the thread', () async {
      await _datasource.saveThreadPref(lunchThread, pref);

      expect(_server.callsTo(_deleteRule), isNotEmpty);
      expect(_server.callsTo(_anyRulePut), isEmpty);
    });

    test('${wire.name} is written in the shared account data', () async {
      await _datasource.saveThreadPref(lunchThread, pref);

      expect(_lastBody(_prefs), {
        'threads': [prefEntry(lunchThread, wire)],
      });
    });
  }

  test('a thread that was never muted has no rule: the choice is still '
      'saved', () async {
    _server.fail(_deleteRule, ServerError.notFound);

    await _datasource.saveThreadPref(lunchThread, ThreadPref.unfollow);

    expect(_lastBody(_prefs), {
      'threads': [prefEntry(lunchThread, WirePref.unfollow)],
    });
  });
}

void _sharedListTests() {
  test('keeps the choices made on the web for other threads, the new one '
      'first', () async {
    await _account.webWrites([
      prefEntry(releaseThread, WirePref.mute),
      prefEntry(lunchThread, WirePref.unfollow),
    ]);

    await _datasource.saveThreadPref(lunchThread, ThreadPref.follow);

    expect(_lastBody(_prefs), {
      'threads': [
        prefEntry(lunchThread, WirePref.follow),
        prefEntry(releaseThread, WirePref.mute),
      ],
    });
  });

  /// The web keeps the last list it wrote (MatrixAccountPrefs.ts): the
  /// account data of the client changes only when the sync comes back.
  test(
    'a choice made before the sync echoed the previous one keeps it',
    () async {
      await _datasource.saveThreadPref(lunchThread, ThreadPref.mute);

      await _datasource.saveThreadPref(releaseThread, ThreadPref.unfollow);

      expect(_lastBody(_prefs), {
        'threads': [
          prefEntry(releaseThread, WirePref.unfollow),
          prefEntry(lunchThread, WirePref.mute),
        ],
      });
    },
  );

  test('a list the web wrote after ours is the one the next choice '
      'starts from', () async {
    await _datasource.saveThreadPref(lunchThread, ThreadPref.mute);
    await _account.webWrites([
      prefEntry(releaseThread, WirePref.follow),
      prefEntry(lunchThread, WirePref.mute),
    ]);

    await _datasource.saveThreadPref(lunchThread, ThreadPref.unfollow);

    expect(_lastBody(_prefs), {
      'threads': [
        prefEntry(lunchThread, WirePref.unfollow),
        prefEntry(releaseThread, WirePref.follow),
      ],
    });
  });
}

void _failureTests() {
  test('a push rule refused: the choice is not shared', () async {
    _server.fail(_muteRule);

    await _expectChangeFails(
      _datasource.saveThreadPref(lunchThread, ThreadPref.mute),
    );
    expect(_server.callsTo(_prefs), isEmpty);
  });

  /// Else the thread would stay silent on the server while every client
  /// shows it followed.
  test('the account data refused after the rule was set: the rule is '
      'removed', () async {
    _server.fail(_prefs);

    await _expectChangeFails(
      _datasource.saveThreadPref(lunchThread, ThreadPref.mute),
    );
    expect(_server.hasPushRule(lunchThread), isFalse);
  });

  /// The list of the server is the base of the save: without it, writing
  /// would erase the choices of the other clients.
  test('the list of the server cannot be read: the change fails, nothing '
      'is written, the thread is not silenced', () async {
    _server.fail(threadPrefsRead);

    await _expectChangeFails(
      _datasource.saveThreadPref(lunchThread, ThreadPref.mute),
    );
    expect(_server.callsTo(_prefs), isEmpty);
    expect(_server.hasPushRule(lunchThread), isFalse);
  });

  test('the account data refused: the change fails', () async {
    _server.fail(_prefs);

    await _expectChangeFails(
      _datasource.saveThreadPref(lunchThread, ThreadPref.follow),
    );
  });
}

void _resolveTests() {
  test('sends the state of the web, keyed by the root', () async {
    await _datasource.saveThreadResolved(lunchThread, resolved: true);

    expect(_lastBody(_resolved), {'resolved': true});
  });

  test('reopening sends resolved false', () async {
    await _datasource.saveThreadResolved(lunchThread, resolved: false);

    expect(_lastBody(_resolved), {'resolved': false});
  });

  test('a state refused: the change fails', () async {
    _server.fail(_resolved);

    await _expectChangeFails(
      _datasource.saveThreadResolved(lunchThread, resolved: true),
    );
  });
}

/// The list of choices the account holds once every write is answered: the
/// last one the server received.
List<Object?> get _finalChoices =>
    (_lastBody(_prefs)! as Map<String, Object?>)['threads']! as List<Object?>;

/// The user mutes the lunch thread, then unfollows the release thread while
/// the requests to [slow] of the first choice get no answer yet.
Future<void> _muteThenUnfollowWhile(ServerRoute slow) async {
  _server.hold(slow);
  final mute = _datasource.saveThreadPref(lunchThread, ThreadPref.mute);
  await pumpEventQueue();
  final unfollow = _datasource.saveThreadPref(
    releaseThread,
    ThreadPref.unfollow,
  );
  await pumpEventQueue();
  _server.release(slow);
  await Future.wait([mute, unfollow]);
}

void _concurrentTests() {
  for (final (slow, what) in [
    (_muteRule, 'push rule'),
    (_prefs, 'list of choices'),
  ]) {
    test('the $what of the first still on its way: the account keeps both '
        'choices', () async {
      await _muteThenUnfollowWhile(slow);

      expect(
        _finalChoices,
        unorderedEquals([
          prefEntry(lunchThread, WirePref.mute),
          prefEntry(releaseThread, WirePref.unfollow),
        ]),
      );
    });

    /// Else the thread stays silent on the server while no client shows it
    /// muted.
    test('the $what of the first still on its way: the thread is silenced '
        'on the server only if the account says it is muted', () async {
      await _muteThenUnfollowWhile(slow);

      expect(
        _server.hasPushRule(lunchThread),
        contains(
          equals(prefEntry(lunchThread, WirePref.mute)),
        ).matches(_finalChoices, {}),
      );
    });
  }

  test('a list the web wrote while the push rule was on its way is not '
      'overwritten', () async {
    _server.hold(_muteRule);
    final mute = _datasource.saveThreadPref(lunchThread, ThreadPref.mute);
    await pumpEventQueue();

    await _account.webWrites([prefEntry(releaseThread, WirePref.follow)]);
    _server.release(_muteRule);
    await mute;

    expect(
      _finalChoices,
      unorderedEquals([
        prefEntry(lunchThread, WirePref.mute),
        prefEntry(releaseThread, WirePref.follow),
      ]),
    );
  });
}
