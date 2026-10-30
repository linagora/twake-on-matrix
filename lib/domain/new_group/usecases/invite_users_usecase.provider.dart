import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/new_group/new_group_repository.provider.dart';
import 'package:twake_chat/domain/new_group/usecases/invite_users_usecase.dart';

part 'invite_users_usecase.provider.g.dart';

@riverpod
InviteUsersUseCase inviteUsersUseCase(Ref ref) =>
    InviteUsersUseCase(ref.watch(newGroupRepositoryProvider));
