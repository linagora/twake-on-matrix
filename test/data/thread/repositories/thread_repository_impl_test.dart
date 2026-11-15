import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/thread/datasources/thread_datasource.dart';
import 'package:twake_chat/data/thread/repositories/thread_repository_impl.dart';
import 'package:twake_chat/domain/thread/entities/thread_replies_page.dart';
import 'package:twake_chat/domain/thread/exceptions/thread_exception.dart';

import '../thread_fixtures.dart';

/// Records what it is asked and answers [outcome], or throws it.
class _FakeThreadDatasource implements ThreadDatasource {
  _FakeThreadDatasource(this.outcome);

  final Object outcome;
  final asked = <(String, ThreadRepliesRequest)>[];

  @override
  Future<ThreadRepliesPage<Event>> getReplies(
    String roomId,
    ThreadRepliesRequest request,
  ) async {
    asked.add((roomId, request));
    final result = outcome;
    if (result is ThreadRepliesPage<Event>) return result;
    throw result;
  }
}

void main() {
  const request = ThreadRepliesRequest(
    rootEventId: threadRootId,
    from: 'batch-1',
  );

  test('the replies are those of the datasource, for the same room '
      'and request', () async {
    const page = ThreadRepliesPage<Event>(replies: [], nextBatch: 'batch-2');
    final datasource = _FakeThreadDatasource(page);

    final result = await ThreadRepositoryImpl(
      datasource,
    ).getReplies(threadRoomId, request);

    expect(result, same(page));
    expect(datasource.asked, [(threadRoomId, request)]);
  });

  test('a thread exception of the datasource reaches the caller as is', () {
    const failure = ThreadRoomNotFoundException(threadRoomId);
    final repository = ThreadRepositoryImpl(_FakeThreadDatasource(failure));

    expect(
      repository.getReplies(threadRoomId, request),
      throwsA(same(failure)),
    );
  });
}
