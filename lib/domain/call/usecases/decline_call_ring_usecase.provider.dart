import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/call/call_repository.provider.dart';
import 'package:twake_chat/domain/call/usecases/decline_call_ring_usecase.dart';

part 'decline_call_ring_usecase.provider.g.dart';

@Riverpod(keepAlive: true)
DeclineCallRingUseCase declineCallRingUseCase(Ref ref) =>
    DeclineCallRingUseCase(ref.watch(callRepositoryProvider));
