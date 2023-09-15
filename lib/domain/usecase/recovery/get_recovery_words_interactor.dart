import 'package:dartz/dartz.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/recovery_words/get_recovery_words_failed.dart';
import 'package:fluffychat/domain/app_state/recovery_words/get_recovery_words_success.dart';
import 'package:fluffychat/domain/model/recovery_words/recovery_words.dart';
import 'package:fluffychat/domain/repository/recovery_words_repository.dart';
import 'package:matrix/matrix.dart';

class GetRecoveryWordsInteractor {
  final RecoveryWordsRepository _recoveryWordsRepository =
      getIt.get<RecoveryWordsRepository>();

  Future<Either<GetRecoveryWordsFailed, GetRecoveryWordsSuccess>>
      execute() async {
    try {
      final RecoveryWords response =
          await _recoveryWordsRepository.getRecoveryWords();
      return Right(GetRecoveryWordsSuccess(words: response));
    } catch (e) {
      Logs().e('GetRecoveryWordsInteractor::execute(): $e');
      return Left(GetRecoveryWordsFailed(exception: e));
    }
  }
}
