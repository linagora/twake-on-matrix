import 'package:twake_chat/domain/thread/entities/thread_replies_page.dart';
import 'package:twake_chat/domain/thread/repositories/thread_repository.dart';

/// Loads the replies of a thread by pages, going up its history.
final class GetThreadRepliesUseCase<T> {
  const GetThreadRepliesUseCase(this._repository);

  static const int pageSize = ThreadRepliesRequest.defaultPageSize;

  final ThreadRepository<T> _repository;

  Future<ThreadRepliesPage<T>> execute({
    required String roomId,
    required ThreadRepliesRequest request,
  }) => _repository.getReplies(roomId, request);
}
