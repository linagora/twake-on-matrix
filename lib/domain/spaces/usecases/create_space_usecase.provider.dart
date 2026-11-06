import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/new_group/new_group_repository.provider.dart';
import 'package:twake_chat/data/repository/spaces/space_repository.provider.dart';
import 'package:twake_chat/domain/spaces/usecases/create_space_usecase.dart';

part 'create_space_usecase.provider.g.dart';

@riverpod
CreateSpaceUseCase createSpaceUseCase(Ref ref) => CreateSpaceUseCase(
  ref.watch(spaceRepositoryProvider),
  ref.watch(newGroupRepositoryProvider),
);
