import 'package:twake_chat/data/datasource/folders/folders_datasource.dart';
import 'package:twake_chat/domain/repository/folders/folders_repository.dart';
import 'package:twake_chat/domain/spaces/folders.dart';

class FoldersRepositoryImpl implements FoldersRepository {
  const FoldersRepositoryImpl(this._datasource);

  final FoldersDatasource _datasource;

  @override
  Stream<List<Folder>> watchFolders() => _datasource.watchFolders();

  @override
  Future<void> saveFolders(
    List<Folder> folders, {
    List<FolderTagChange> changes = const [],
  }) => _datasource.saveFolders(folders, changes: changes);
}
