import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/model/thread/thread_prefs.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';

/// THR-M-07 and spec § 4 « Suivre / muet »: the account data
/// `app.twake.chat.thread_prefs` is shared with the web
/// (twake-space-chat `src/domain/threadFollow.ts`, D60):
/// `{ "threads": [{ "roomId", "threadId", "pref" }] }`, `pref` in `follow`,
/// `unfollow`, `mute`; 500 entries at most, the newest first, the oldest
/// dropped; malformed entries are ignored on read.
void main() {
  group('the account data type', () {
    test('is the one of the web', () {
      expect(threadPrefsAccountDataType, 'app.twake.chat.thread_prefs');
    });
  });

  group('reading what a client wrote', _readTests);
  group('a choice of the user', _choiceTests);
  group('500 choices at most', _capTests);
  group('an explicit choice over taking part', _followTests);
}

const _lunch = ThreadRef('!team:example.org', r'$lunch');
const _release = ThreadRef('!team:example.org', r'$release');
const _elsewhere = ThreadRef('!other:example.org', r'$lunch');

/// The `pref` values of the web, spelled as on the wire; `snooze` is a kind
/// no client knows.
enum _Wire { follow, unfollow, mute, snooze }

Map<String, Object?> _entry(ThreadRef thread, _Wire pref) => {
  'roomId': thread.roomId,
  'threadId': thread.rootEventId,
  'pref': pref.name,
};

ThreadPrefs _read(List<Object?> threads) =>
    ThreadPrefs.fromAccountData({'threads': threads});

/// 500 distinct threads of one room, the first one newest: the list is full.
List<Map<String, Object?>> _fullList() => [
  for (var i = 0; i < 500; i++)
    _entry(ThreadRef('!team:example.org', '\$thread$i'), _Wire.follow),
];

void _readTests() {
  test('each of the three choices is read back', () {
    final prefs = _read([
      _entry(_lunch, _Wire.follow),
      _entry(_release, _Wire.mute),
      _entry(_elsewhere, _Wire.unfollow),
    ]);

    expect(prefs.of(_lunch), ThreadPref.follow);
    expect(prefs.of(_release), ThreadPref.mute);
    expect(prefs.of(_elsewhere), ThreadPref.unfollow);
  });

  test('a thread without a choice has none', () {
    expect(_read([_entry(_lunch, _Wire.follow)]).of(_release), isNull);
  });

  test('the same root in another room is another thread', () {
    expect(_read([_entry(_lunch, _Wire.mute)]).of(_elsewhere), isNull);
  });

  test('no account data yet: no choice at all', () {
    expect(ThreadPrefs.fromAccountData(null).of(_lunch), isNull);
  });

  test('a content without a list of threads: no choice at all', () {
    expect(
      ThreadPrefs.fromAccountData({'threads': 'follow'}).of(_lunch),
      isNull,
    );
  });

  test('an entry of an unknown kind is ignored, the others are kept', () {
    final prefs = _read([
      _entry(_lunch, _Wire.snooze),
      _entry(_release, _Wire.mute),
    ]);

    expect(prefs.of(_lunch), isNull);
    expect(prefs.of(_release), ThreadPref.mute);
  });

  test('an entry that is not an object is ignored, the others are kept', () {
    final prefs = _read(['follow', null, 42, _entry(_release, _Wire.follow)]);

    expect(prefs.of(_release), ThreadPref.follow);
  });

  test('an entry without a room or a thread id is ignored', () {
    final prefs = _read([
      {'threadId': _lunch.rootEventId, 'pref': 'mute'},
      {'roomId': _release.roomId, 'threadId': 7, 'pref': 'mute'},
      _entry(_elsewhere, _Wire.mute),
    ]);

    expect(prefs.of(_lunch), isNull);
    expect(prefs.of(_release), isNull);
    expect(prefs.of(_elsewhere), ThreadPref.mute);
  });

  /// The web reads the list into a `Map` (MatrixAccountPrefs.ts
  /// `threadPrefs`): of two entries of one thread, the later one is kept.
  test('a thread written twice by another client: its last entry wins, as '
      'on the web', () {
    final prefs = _read([
      _entry(_lunch, _Wire.follow),
      _entry(_release, _Wire.mute),
      _entry(_lunch, _Wire.mute),
    ]);

    expect(prefs.of(_lunch), ThreadPref.mute);
    expect(prefs.of(_release), ThreadPref.mute);
  });
}

void _choiceTests() {
  test('is written in the format of the web', () {
    final prefs = const ThreadPrefs.empty().withChoice(_lunch, ThreadPref.mute);

    expect(prefs.toAccountData(), {
      'threads': [_entry(_lunch, _Wire.mute)],
    });
  });

  test('comes first, before the older ones', () {
    final prefs = _read([
      _entry(_release, _Wire.follow),
    ]).withChoice(_lunch, ThreadPref.unfollow);

    expect(prefs.toAccountData(), {
      'threads': [
        _entry(_lunch, _Wire.unfollow),
        _entry(_release, _Wire.follow),
      ],
    });
  });

  test('replaces the previous choice for the thread and moves it first', () {
    final prefs = _read([
      _entry(_release, _Wire.follow),
      _entry(_lunch, _Wire.follow),
    ]).withChoice(_lunch, ThreadPref.mute);

    expect(prefs.toAccountData(), {
      'threads': [_entry(_lunch, _Wire.mute), _entry(_release, _Wire.follow)],
    });
  });

  test('keeps the choices of the other rooms', () {
    final prefs = _read([
      _entry(_elsewhere, _Wire.mute),
    ]).withChoice(_lunch, ThreadPref.follow);

    expect(prefs.of(_elsewhere), ThreadPref.mute);
    expect(prefs.of(_lunch), ThreadPref.follow);
  });

  test('does not change the choices it was made from', () {
    final before = _read([_entry(_lunch, _Wire.follow)]);

    before.withChoice(_lunch, ThreadPref.mute);

    expect(before.of(_lunch), ThreadPref.follow);
  });
}

void _capTests() {
  test('a 501st choice drops the oldest one, 500 are kept', () {
    final full = _fullList();

    final threads =
        _read(
              full,
            ).withChoice(_lunch, ThreadPref.follow).toAccountData()['threads']
            as List;

    expect(threads, hasLength(500));
    expect(threads.first, _entry(_lunch, _Wire.follow));
    expect(threads.last, full[498]);
    expect(threads, isNot(contains(full[499])));
  });

  test('a new choice for a thread already among 500 drops none', () {
    final full = _fullList();
    const thread = ThreadRef('!team:example.org', r'$thread250');

    final threads =
        _read(
              full,
            ).withChoice(thread, ThreadPref.mute).toAccountData()['threads']
            as List;

    expect(threads, hasLength(500));
    expect(threads.first, _entry(thread, _Wire.mute));
    expect(threads.last, full[499]);
  });
}

void _followTests() {
  test('no choice: following is taking part', () {
    expect(
      ThreadFollow.resolve(participated: true),
      const ThreadFollow(isFollowing: true, isMuted: false),
    );
    expect(
      ThreadFollow.resolve(participated: false),
      const ThreadFollow(isFollowing: false, isMuted: false),
    );
  });

  test('a thread the user wrote in, then unfollowed, is not followed', () {
    expect(
      ThreadFollow.resolve(participated: true, pref: ThreadPref.unfollow),
      const ThreadFollow(isFollowing: false, isMuted: false),
    );
  });

  test('a thread followed without taking part is followed', () {
    expect(
      ThreadFollow.resolve(participated: false, pref: ThreadPref.follow),
      const ThreadFollow(isFollowing: true, isMuted: false),
    );
  });

  test('a muted thread stays followed', () {
    expect(
      ThreadFollow.resolve(participated: false, pref: ThreadPref.mute),
      const ThreadFollow(isFollowing: true, isMuted: true),
    );
  });
}
