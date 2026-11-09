import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/folders/folders_repository.provider.dart';
import 'package:twake_chat/domain/spaces/usecases/watch_folders_usecase.dart';

part 'watch_folders_usecase.provider.g.dart';

@riverpod
WatchFoldersUseCase watchFoldersUseCase(Ref ref) =>
    WatchFoldersUseCase(ref.watch(foldersRepositoryProvider));
