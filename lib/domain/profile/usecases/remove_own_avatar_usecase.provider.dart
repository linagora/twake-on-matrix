import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/profile/repositories/profile_repository_impl.provider.dart';
import 'package:twake_chat/domain/profile/usecases/remove_own_avatar_usecase.dart';

part 'remove_own_avatar_usecase.provider.g.dart';

@riverpod
RemoveOwnAvatarUseCase removeOwnAvatarUseCase(Ref ref) =>
    RemoveOwnAvatarUseCase(ref.watch(profileRepositoryProvider));
