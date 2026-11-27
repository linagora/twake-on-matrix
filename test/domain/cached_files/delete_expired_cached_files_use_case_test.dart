import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/cached_files/repositories/cached_files_repository.dart';
import 'package:twake_chat/domain/cached_files/usecases/delete_expired_cached_files_use_case.dart';

class _Repository implements CachedFilesRepository {
  final cutoffs = <DateTime>[];

  @override
  Future<void> deleteFilesCachedBefore(DateTime cutoff) async =>
      cutoffs.add(cutoff);
}

void main() {
  test('deletes the files cached more than 7 days ago', () async {
    final repository = _Repository();
    final useCase = DeleteExpiredCachedFilesUseCase(
      repository,
      now: () => DateTime(2026, 11, 27, 12),
    );

    await useCase.execute();

    expect(repository.cutoffs, [DateTime(2026, 11, 20, 12)]);
  });
}
