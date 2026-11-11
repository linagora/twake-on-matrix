import 'package:twake_chat/domain/thread/entities/thread_replies_page.dart';

/// Reads the replies of a thread. [T] is the reply type of the data source.
abstract class ThreadRepository<T> {
  Future<ThreadRepliesPage<T>> getReplies(
    String roomId,
    ThreadRepliesRequest request,
  );
}
