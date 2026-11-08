import 'package:twake_chat/domain/repository/folders/folders_repository.dart';
import 'package:twake_chat/domain/spaces/folders.dart';

class SaveFoldersUseCase {
  const SaveFoldersUseCase(this._repository);

  final FoldersRepository _repository;

  /// Saves every folder at once, in this order, with their tag changes.
  ///
  /// Throws a `FolderSaveFailedException`.
  Future<void> execute(
    List<Folder> folders, {
    List<FolderTagChange> changes = const [],
  }) => _repository.saveFolders(folders, changes: changes);
}
