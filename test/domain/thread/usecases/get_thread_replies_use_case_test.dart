import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/thread/entities/thread_replies_page.dart';
import 'package:twake_chat/domain/thread/exceptions/thread_exception.dart';
import 'package:twake_chat/domain/thread/repositories/thread_repository.dart';
import 'package:twake_chat/domain/thread/usecases/get_thread_replies_use_case.dart';

class _FakeThreadRepository implements ThreadRepository<String> {
  _FakeThreadRepository(this.outcome);

  final Object outcome;
  final asked = <(String, ThreadRepliesRequest)>[];

  @override
  Future<ThreadRepliesPage<String>> getReplies(
    String roomId,
    ThreadRepliesRequest request,
  ) async {
    asked.add((roomId, request));
    final result = outcome;
    if (result is ThreadRepliesPage<String>) return result;
    throw result;
  }
}

void main() {
  const roomId = '!room:example.com';
  const request = ThreadRepliesRequest(rootEventId: r'$root', from: 'batch-1');

  test('the page of the repository is the page of the thread', () async {
    const page = ThreadRepliesPage<String>(
      replies: ['a', 'b'],
      nextBatch: 'batch-2',
    );
    final repository = _FakeThreadRepository(page);

    final result = await GetThreadRepliesUseCase<String>(
      repository,
    ).execute(roomId: roomId, request: request);

    expect(result, same(page));
    expect(repository.asked, [(roomId, request)]);
  });

  test('a thread exception reaches the caller as is', () {
    const failure = ThreadLoadFailedException(roomId);
    final useCase = GetThreadRepliesUseCase<String>(
      _FakeThreadRepository(failure),
    );

    expect(
      useCase.execute(roomId: roomId, request: request),
      throwsA(same(failure)),
    );
  });

  test('a request asks for a page of the default size from the start', () {
    const first = ThreadRepliesRequest(rootEventId: r'$root');

    expect(first.limit, ThreadRepliesRequest.defaultPageSize);
    expect(first.from, isNull);
  });
}
