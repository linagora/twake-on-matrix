import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/thread/repositories/thread_repository.provider.dart';
import 'package:twake_chat/domain/thread/usecases/get_thread_replies_use_case.dart';

part 'get_thread_replies_use_case.provider.g.dart';

@riverpod
GetThreadRepliesUseCase<Event> getThreadRepliesUseCase(
  Ref ref,
  Client client,
) => GetThreadRepliesUseCase(ref.watch(threadRepositoryProvider(client)));
