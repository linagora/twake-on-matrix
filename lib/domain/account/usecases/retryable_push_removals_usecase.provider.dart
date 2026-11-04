import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/account/repositories/account_repository_impl.provider.dart';
import 'package:twake_chat/domain/account/usecases/retryable_push_removals_usecase.dart';

part 'retryable_push_removals_usecase.provider.g.dart';

@riverpod
RetryablePushRemovalsUseCase retryablePushRemovalsUseCase(Ref ref) =>
    RetryablePushRemovalsUseCase(
      repository: ref.watch(accountRepositoryProvider),
    );
