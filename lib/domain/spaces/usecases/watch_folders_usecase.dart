import 'package:twake_chat/domain/repository/folders/folders_repository.dart';
import 'package:twake_chat/domain/spaces/folders.dart';

class WatchFoldersUseCase {
  const WatchFoldersUseCase(this._repository);

  final FoldersRepository _repository;

  Stream<List<Folder>> execute() => _repository.watchFolders();
}
