import 'package:twake_chat/data/cached_files/datasources/cached_files_datasource.dart';
import 'package:twake_chat/domain/cached_files/repositories/cached_files_repository.dart';

class CachedFilesRepositoryImpl implements CachedFilesRepository {
  const CachedFilesRepositoryImpl(this._datasource);

  final CachedFilesDatasource _datasource;

  @override
  Future<void> deleteFilesCachedBefore(DateTime cutoff) =>
      _datasource.deleteFilesCachedBefore(cutoff);
}
