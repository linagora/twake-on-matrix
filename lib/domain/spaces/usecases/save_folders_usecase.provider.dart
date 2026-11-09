import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/folders/folders_repository.provider.dart';
import 'package:twake_chat/domain/spaces/usecases/save_folders_usecase.dart';

part 'save_folders_usecase.provider.g.dart';

@riverpod
SaveFoldersUseCase saveFoldersUseCase(Ref ref) =>
    SaveFoldersUseCase(ref.watch(foldersRepositoryProvider));
