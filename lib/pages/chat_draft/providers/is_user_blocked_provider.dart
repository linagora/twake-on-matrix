import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/direct_chat/usecases/watch_user_blocked_usecase.provider.dart';

part 'is_user_blocked_provider.g.dart';

/// Whether [matrixId] is blocked by the active account; false until the first
/// value arrives.
@riverpod
Stream<bool> isUserBlocked(Ref ref, String matrixId) =>
    ref.watch(watchUserBlockedUseCaseProvider).execute(matrixId);
