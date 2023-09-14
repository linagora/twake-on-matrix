import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/recovery_words/delete_recovery_states.dart';
import 'package:fluffychat/domain/repository/recovery_words_repository.dart';
import 'package:matrix/matrix.dart';

class DeleteRecoveryWordsInteractor {
  final RecoveryWordsRepository recoveryWordsRepository =
      getIt.get<RecoveryWordsRepository>();

  Future<Either<Failure, Success>> execute() async {
    try {
      final bool response = await recoveryWordsRepository.deleteRecoveryWords();
      return response
          ? const Right(DeleteRecoveryWordsSuccess())
          : const Left(DeleteRecoveryWordsFailed());
    } catch (e) {
      Logs().e('DeleteRecoveryWordsInteractor::execute() [Exception]', e);
      return Left(DeleteRecoveryWordsFailed(exception: e));
    }
  }
}
