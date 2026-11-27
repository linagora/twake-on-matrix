import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/cached_files/datasources_impl/cached_files_datasource.provider.dart';
import 'package:twake_chat/data/cached_files/repositories/cached_files_repository_impl.dart';
import 'package:twake_chat/domain/cached_files/repositories/cached_files_repository.dart';

part 'cached_files_repository.provider.g.dart';

@riverpod
CachedFilesRepository cachedFilesRepository(Ref ref) =>
    CachedFilesRepositoryImpl(ref.watch(cachedFilesDatasourceProvider));
