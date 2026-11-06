import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/spaces/space_repository.provider.dart';
import 'package:twake_chat/domain/spaces/usecases/open_space_usecase.dart';

part 'open_space_usecase.provider.g.dart';

@riverpod
OpenSpaceUseCase openSpaceUseCase(Ref ref) =>
    OpenSpaceUseCase(ref.watch(spaceRepositoryProvider));
