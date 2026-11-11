import 'package:twake_chat/domain/model/thread/thread_prefs.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/model/thread/thread_status.dart';

abstract class ThreadPrefsDatasource {
  /// The status of the thread now, then at each change.
  Stream<ThreadStatus> watchThread(ThreadRef thread);

  /// Throws a `ThreadChangeFailedException`.
  Future<void> saveThreadPref(ThreadRef thread, ThreadPref pref);

  /// Throws a `ThreadChangeFailedException`.
  Future<void> saveThreadResolved(ThreadRef thread, {required bool resolved});
}
