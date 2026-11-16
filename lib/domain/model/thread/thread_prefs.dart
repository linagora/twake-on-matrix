import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';

part 'thread_prefs.freezed.dart';

/// Account data shared with the web (`threadFollow.ts`): the choices of the
/// user about threads.
const threadPrefsAccountDataType = 'app.twake.chat.thread_prefs';

/// The web keeps this many choices, the newest first.
const _maxChoices = 500;

/// The explicit choice of the user about one thread; its `name` is the
/// `pref` of the wire.
enum ThreadPref { follow, unfollow, mute }

/// Whether the user follows a thread, and whether it is muted.
@freezed
abstract class ThreadFollow with _$ThreadFollow {
  const factory ThreadFollow({
    required bool isFollowing,
    required bool isMuted,
  }) = _ThreadFollow;

  /// An explicit choice wins over taking part; a muted thread stays followed.
  factory ThreadFollow.resolve({
    required bool participated,
    ThreadPref? pref,
  }) => ThreadFollow(
    isFollowing: switch (pref) {
      ThreadPref.follow || ThreadPref.mute => true,
      ThreadPref.unfollow => false,
      null => participated,
    },
    isMuted: pref == ThreadPref.mute,
  );
}

/// The choices of `app.twake.chat.thread_prefs`:
/// `{ "threads": [{ "roomId", "threadId", "pref" }] }`, newest first.
class ThreadPrefs {
  const ThreadPrefs.empty() : _choices = const {};

  const ThreadPrefs._(this._choices);

  /// Malformed entries are ignored; the last entry of a thread wins, as in the
  /// `Map` the web builds from the list.
  factory ThreadPrefs.fromAccountData(Map<String, Object?>? content) {
    final threads = content?['threads'];
    if (threads is! List) return const ThreadPrefs.empty();
    final choices = <ThreadRef, ThreadPref>{};
    for (final entry in threads) {
      final parsed = _parse(entry);
      if (parsed != null) choices[parsed.$1] = parsed.$2;
    }
    return ThreadPrefs._(choices);
  }

  final Map<ThreadRef, ThreadPref> _choices;

  static (ThreadRef, ThreadPref)? _parse(Object? entry) {
    if (entry is! Map) return null;
    final room = entry['roomId'];
    final thread = entry['threadId'];
    final pref = ThreadPref.values.asNameMap()[entry['pref']];
    if (room is! String || thread is! String || pref == null) return null;
    return (ThreadRef(room, thread), pref);
  }

  ThreadPref? of(ThreadRef thread) => _choices[thread];

  /// The threads the user made a choice about.
  Iterable<ThreadRef> get threads => _choices.keys;

  /// The choice comes first; the oldest ones go past the cap.
  ThreadPrefs withChoice(ThreadRef thread, ThreadPref pref) => ThreadPrefs._(
    Map.fromEntries(
      [
        MapEntry(thread, pref),
        ..._choices.entries.where((choice) => choice.key != thread),
      ].take(_maxChoices),
    ),
  );

  Map<String, Object?> toAccountData() => {
    'threads': [
      for (final choice in _choices.entries)
        {
          'roomId': choice.key.roomId,
          'threadId': choice.key.rootEventId,
          'pref': choice.value.name,
        },
    ],
  };
}
