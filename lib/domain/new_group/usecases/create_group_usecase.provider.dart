import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/new_group/new_group_repository.provider.dart';
import 'package:twake_chat/domain/new_group/usecases/create_group_usecase.dart';

part 'create_group_usecase.provider.g.dart';

@riverpod
CreateGroupUseCase createGroupUseCase(Ref ref) =>
    CreateGroupUseCase(ref.watch(newGroupRepositoryProvider));
