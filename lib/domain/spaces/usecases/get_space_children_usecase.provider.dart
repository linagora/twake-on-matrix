import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/spaces/space_repository.provider.dart';
import 'package:twake_chat/domain/spaces/usecases/get_space_children_usecase.dart';

part 'get_space_children_usecase.provider.g.dart';

@riverpod
GetSpaceChildrenUseCase getSpaceChildrenUseCase(Ref ref) =>
    GetSpaceChildrenUseCase(ref.watch(spaceRepositoryProvider));
