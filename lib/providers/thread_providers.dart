import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/thread/repositories/thread_repository_impl.dart';
import 'package:twake_chat/domain/thread/repositories/thread_repository.dart';
import 'package:twake_chat/domain/thread/usecases/get_thread_replies_use_case.dart';

part 'thread_providers.g.dart';

@riverpod
ThreadRepository<Event> threadRepository(Ref ref, Client client) =>
    ThreadRepositoryImpl(client);

@riverpod
GetThreadRepliesUseCase<Event> getThreadRepliesUseCase(
  Ref ref,
  Client client,
) => GetThreadRepliesUseCase(ref.watch(threadRepositoryProvider(client)));
