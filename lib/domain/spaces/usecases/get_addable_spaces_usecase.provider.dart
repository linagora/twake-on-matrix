import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/spaces/space_repository.provider.dart';
import 'package:twake_chat/domain/spaces/usecases/get_addable_spaces_usecase.dart';

part 'get_addable_spaces_usecase.provider.g.dart';

@riverpod
GetAddableSpacesUseCase getAddableSpacesUseCase(Ref ref) =>
    GetAddableSpacesUseCase(ref.watch(spaceRepositoryProvider));
