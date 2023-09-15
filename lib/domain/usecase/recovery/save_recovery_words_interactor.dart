import 'package:dartz/dartz.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/recovery_words/save_recovery_words_failed.dart';
import 'package:fluffychat/domain/app_state/recovery_words/save_recovery_words_success.dart';
import 'package:fluffychat/domain/repository/recovery_words_repository.dart';
import 'package:matrix/matrix.dart';

class SaveRecoveryWordsInteractor {
  final RecoveryWordsRepository recoveryWordsRepository =
      getIt.get<RecoveryWordsRepository>();

  Future<Either<SaveRecoveryWordsFailed, SaveRecoveryWordsSuccess>> execute(
    String words,
  ) async {
    try {
      final bool response =
          await recoveryWordsRepository.saveRecoveryWords(words);
      return response
          ? const Right(SaveRecoveryWordsSuccess())
          : const Left(SaveRecoveryWordsFailed());
    } catch (e) {
      Logs().e('SaveRecoveryWordsInteractor::execute() [Exception]', e);
      return Left(SaveRecoveryWordsFailed(exception: e));
    }
  }
}
