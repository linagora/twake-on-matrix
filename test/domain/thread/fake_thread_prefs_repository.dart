import 'dart:async';

import 'package:twake_chat/domain/exception/thread/thread_change_exception.dart';
import 'package:twake_chat/domain/model/thread/thread_prefs.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/model/thread/thread_status.dart';
import 'package:twake_chat/domain/thread/repositories/thread_prefs_repository.dart';

const lunchThread = ThreadRef('!team:example.org', r'$lunch');

const notFollowed = ThreadFollow(isFollowing: false, isMuted: false);
const followed = ThreadFollow(isFollowing: true, isMuted: false);
const muted = ThreadFollow(isFollowing: true, isMuted: true);

/// What the account says of the lunch thread; the user may resolve it unless
/// told otherwise.
ThreadStatus statusOf(ThreadFollow follow, {bool isResolved = false}) =>
    ThreadStatus(follow: follow, isResolved: isResolved, canResolve: true);

/// A status of a thread the user may not resolve.
ThreadStatus withoutResolve(ThreadFollow follow) =>
    ThreadStatus(follow: follow, isResolved: false, canResolve: false);

/// One change asked of the account.
sealed class ThreadChange {
  const ThreadChange(this.thread);

  final ThreadRef thread;
}

class PrefSaved extends ThreadChange {
  const PrefSaved(super.thread, this.pref);

  final ThreadPref pref;

  @override
  bool operator ==(Object other) =>
      other is PrefSaved && other.thread == thread && other.pref == pref;

  @override
  int get hashCode => Object.hash(thread, pref);

  @override
  String toString() => 'PrefSaved($thread, $pref)';
}

class ResolvedSaved extends ThreadChange {
  const ResolvedSaved(super.thread, {required this.resolved});

  final bool resolved;

  @override
  bool operator ==(Object other) =>
      other is ResolvedSaved &&
      other.thread == thread &&
      other.resolved == resolved;

  @override
  int get hashCode => Object.hash(thread, resolved);

  @override
  String toString() => 'ResolvedSaved($thread, resolved: $resolved)';
}

/// The account of the user, as the thread screen reaches it: what it says of
/// a thread (pushed by [show]), and every change asked of it.
class FakeThreadPrefsRepository implements ThreadPrefsRepository {
  final _statuses = StreamController<ThreadStatus>.broadcast();
  final List<ThreadChange> changes = [];

  /// The next changes fail, as a server that refuses them.
  bool isDown = false;

  /// While set and not completed, the changes wait for it, as a slow server.
  Completer<void>? slowServer;

  /// The account (a sync, the web) now says [status].
  void show(ThreadStatus status) => _statuses.add(status);

  /// What the account says of the thread cannot be read (the rooms fail to
  /// load, no account).
  void failWatching() =>
      _statuses.addError(StateError('The rooms could not be loaded'));

  Future<void> close() => _statuses.close();

  @override
  Stream<ThreadStatus> watchThread(ThreadRef thread) => _statuses.stream;

  @override
  Future<void> saveThreadPref(ThreadRef thread, ThreadPref pref) =>
      _record(PrefSaved(thread, pref));

  @override
  Future<void> saveThreadResolved(ThreadRef thread, {required bool resolved}) =>
      _record(ResolvedSaved(thread, resolved: resolved));

  Future<void> _record(ThreadChange change) async {
    changes.add(change);
    await slowServer?.future;
    if (isDown) throw const ThreadChangeFailedException();
  }
}
