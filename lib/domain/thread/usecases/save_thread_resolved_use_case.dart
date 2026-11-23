import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/thread/repositories/thread_prefs_repository.dart';

/// Saves the resolved state of a thread in its room. Throws a
/// `ThreadChangeFailedException`.
final class SaveThreadResolvedUseCase {
  const SaveThreadResolvedUseCase(this._repository);

  final ThreadPrefsRepository _repository;

  Future<void> execute(ThreadRef thread, {required bool resolved}) =>
      _repository.saveThreadResolved(thread, resolved: resolved);
}
