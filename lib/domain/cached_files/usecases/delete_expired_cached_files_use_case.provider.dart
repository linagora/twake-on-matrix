import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/cached_files/repositories/cached_files_repository.provider.dart';
import 'package:twake_chat/domain/cached_files/usecases/delete_expired_cached_files_use_case.dart';

part 'delete_expired_cached_files_use_case.provider.g.dart';

@riverpod
DeleteExpiredCachedFilesUseCase deleteExpiredCachedFilesUseCase(Ref ref) =>
    DeleteExpiredCachedFilesUseCase(ref.watch(cachedFilesRepositoryProvider));
