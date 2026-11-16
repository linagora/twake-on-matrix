import 'package:twake_chat/domain/model/thread/thread_prefs.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/thread/repositories/thread_prefs_repository.dart';

/// Saves the choice of the user on a thread in the account. Throws a
/// `ThreadChangeFailedException`.
final class SaveThreadPrefUseCase {
  const SaveThreadPrefUseCase(this._repository);

  final ThreadPrefsRepository _repository;

  Future<void> execute(ThreadRef thread, ThreadPref pref) =>
      _repository.saveThreadPref(thread, pref);
}
