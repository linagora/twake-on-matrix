import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/model/thread/thread_status.dart';
import 'package:twake_chat/domain/thread/repositories/thread_prefs_repository.dart';

/// The status of a thread now, then at each change.
final class WatchThreadUseCase {
  const WatchThreadUseCase(this._repository);

  final ThreadPrefsRepository _repository;

  Stream<ThreadStatus> execute(ThreadRef thread) =>
      _repository.watchThread(thread);
}
