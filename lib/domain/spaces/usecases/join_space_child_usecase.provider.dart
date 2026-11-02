import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/spaces/space_repository.provider.dart';
import 'package:twake_chat/domain/spaces/usecases/join_space_child_usecase.dart';

part 'join_space_child_usecase.provider.g.dart';

@riverpod
JoinSpaceChildUseCase joinSpaceChildUseCase(Ref ref) =>
    JoinSpaceChildUseCase(ref.watch(spaceRepositoryProvider));
