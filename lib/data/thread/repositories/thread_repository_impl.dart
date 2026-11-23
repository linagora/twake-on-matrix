import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/thread/datasources/thread_datasource.dart';
import 'package:twake_chat/domain/thread/entities/thread_replies_page.dart';
import 'package:twake_chat/domain/thread/repositories/thread_repository.dart';

class ThreadRepositoryImpl implements ThreadRepository<Event> {
  const ThreadRepositoryImpl(this._datasource);

  final ThreadDatasource _datasource;

  @override
  Future<ThreadRepliesPage<Event>> getReplies(
    String roomId,
    ThreadRepliesRequest request,
  ) => _datasource.getReplies(roomId, request);
}
