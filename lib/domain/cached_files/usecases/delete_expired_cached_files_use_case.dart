import 'package:twake_chat/domain/cached_files/repositories/cached_files_repository.dart';

class DeleteExpiredCachedFilesUseCase {
  const DeleteExpiredCachedFilesUseCase(
    this._repository, {
    DateTime Function() now = DateTime.now,
  }) : _now = now;

  static const maxAge = Duration(days: 7);

  final CachedFilesRepository _repository;
  final DateTime Function() _now;

  Future<void> execute() =>
      _repository.deleteFilesCachedBefore(_now().subtract(maxAge));
}
