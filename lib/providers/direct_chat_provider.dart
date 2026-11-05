import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/direct_chat/repositories/direct_chat_repository_impl.dart';
import 'package:twake_chat/data/direct_chat/repositories/ignored_users_repository_impl.dart';
import 'package:twake_chat/domain/direct_chat/repositories/direct_chat_repository.dart';
import 'package:twake_chat/domain/direct_chat/repositories/ignored_users_repository.dart';
import 'package:twake_chat/domain/direct_chat/usecases/create_direct_chat_usecase.dart';
import 'package:twake_chat/domain/direct_chat/usecases/watch_user_blocked_usecase.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

part 'direct_chat_provider.g.dart';

@riverpod
DirectChatRepository directChatRepository(Ref ref) =>
    DirectChatRepositoryImpl(ref.watch(activeMatrixClientProvider));

@riverpod
IgnoredUsersRepository ignoredUsersRepository(Ref ref) =>
    IgnoredUsersRepositoryImpl(ref.watch(activeMatrixClientProvider));

@riverpod
CreateDirectChatUseCase createDirectChatUseCase(Ref ref) =>
    CreateDirectChatUseCase(ref.watch(directChatRepositoryProvider));

@riverpod
WatchUserBlockedUseCase watchUserBlockedUseCase(Ref ref) =>
    WatchUserBlockedUseCase(ref.watch(ignoredUsersRepositoryProvider));
