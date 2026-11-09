import 'package:twake_chat/domain/spaces/folders.dart';

abstract class FoldersRepository {
  /// The folders saved now, then at each change.
  Stream<List<Folder>> watchFolders();

  /// Throws a `FolderSaveFailedException`.
  Future<void> saveFolders(
    List<Folder> folders, {
    List<FolderTagChange> changes = const [],
  });
}
