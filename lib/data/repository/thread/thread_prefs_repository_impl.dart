import 'package:twake_chat/data/datasource/thread/thread_prefs_datasource.dart';
import 'package:twake_chat/domain/model/thread/thread_prefs.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/model/thread/thread_status.dart';
import 'package:twake_chat/domain/thread/repositories/thread_prefs_repository.dart';

class ThreadPrefsRepositoryImpl implements ThreadPrefsRepository {
  const ThreadPrefsRepositoryImpl(this._datasource);

  final ThreadPrefsDatasource _datasource;

  @override
  Stream<ThreadStatus> watchThread(ThreadRef thread) =>
      _datasource.watchThread(thread);

  @override
  Future<void> saveThreadPref(ThreadRef thread, ThreadPref pref) =>
      _datasource.saveThreadPref(thread, pref);

  @override
  Future<void> saveThreadResolved(ThreadRef thread, {required bool resolved}) =>
      _datasource.saveThreadResolved(thread, resolved: resolved);
}
