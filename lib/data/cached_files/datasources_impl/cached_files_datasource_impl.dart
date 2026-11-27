import 'package:twake_chat/data/cached_files/datasources/cached_files_datasource.dart';
import 'package:twake_chat/utils/manager/storage_directory_manager.dart';

class CachedFilesDatasourceImpl implements CachedFilesDatasource {
  const CachedFilesDatasourceImpl(this._storage);

  final StorageDirectoryManager _storage;

  @override
  Future<void> deleteFilesCachedBefore(DateTime cutoff) =>
      _storage.deleteFilesCachedBefore(cutoff);
}
