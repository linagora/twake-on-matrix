import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/call/call_repository.provider.dart';
import 'package:twake_chat/domain/call/usecases/watch_call_ring_declined_usecase.dart';

part 'watch_call_ring_declined_usecase.provider.g.dart';

@Riverpod(keepAlive: true)
WatchCallRingDeclinedUseCase watchCallRingDeclinedUseCase(Ref ref) =>
    WatchCallRingDeclinedUseCase(ref.watch(callRepositoryProvider));
