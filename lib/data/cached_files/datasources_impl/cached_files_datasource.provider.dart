import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/cached_files/datasources/cached_files_datasource.dart';
import 'package:twake_chat/data/cached_files/datasources_impl/cached_files_datasource_impl.dart';
import 'package:twake_chat/utils/manager/storage_directory_manager.dart';

part 'cached_files_datasource.provider.g.dart';

@riverpod
CachedFilesDatasource cachedFilesDatasource(Ref ref) =>
    CachedFilesDatasourceImpl(StorageDirectoryManager.instance);
