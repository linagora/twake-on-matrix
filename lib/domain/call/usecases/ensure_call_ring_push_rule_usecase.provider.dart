import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/call/call_repository.provider.dart';
import 'package:twake_chat/domain/call/usecases/ensure_call_ring_push_rule_usecase.dart';

part 'ensure_call_ring_push_rule_usecase.provider.g.dart';

@Riverpod(keepAlive: true)
EnsureCallRingPushRuleUseCase ensureCallRingPushRuleUseCase(Ref ref) =>
    EnsureCallRingPushRuleUseCase(ref.watch(callRepositoryProvider));
