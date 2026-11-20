import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/direct_chat/repositories/ignored_users_repository_impl.provider.dart';
import 'package:twake_chat/domain/direct_chat/usecases/watch_user_blocked_usecase.dart';

part 'watch_user_blocked_usecase.provider.g.dart';

@riverpod
WatchUserBlockedUseCase watchUserBlockedUseCase(Ref ref) =>
    WatchUserBlockedUseCase(ref.watch(ignoredUsersRepositoryProvider));
