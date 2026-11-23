import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/thread/entities/thread_replies_page.dart';

abstract class ThreadDatasource {
  Future<ThreadRepliesPage<Event>> getReplies(
    String roomId,
    ThreadRepliesRequest request,
  );
}
