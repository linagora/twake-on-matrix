import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/account/repositories/account_repository_impl.provider.dart';
import 'package:twake_chat/domain/account/usecases/prune_pending_push_removals_usecase.dart';

part 'prune_pending_push_removals_usecase.provider.g.dart';

@riverpod
PrunePendingPushRemovalsUseCase prunePendingPushRemovalsUseCase(Ref ref) =>
    PrunePendingPushRemovalsUseCase(
      repository: ref.watch(accountRepositoryProvider),
    );

@riverpod
RetryablePushRemovalsUseCase retryablePushRemovalsUseCase(Ref ref) =>
    RetryablePushRemovalsUseCase(
      repository: ref.watch(accountRepositoryProvider),
    );
