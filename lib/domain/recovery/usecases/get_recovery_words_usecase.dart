import 'package:twake_chat/domain/model/recovery_words/recovery_words.dart';
import 'package:twake_chat/domain/recovery/exceptions/recovery_words_exception.dart';
import 'package:twake_chat/domain/repository/recovery_words_repository.dart';

class GetRecoveryWordsUseCase {
  const GetRecoveryWordsUseCase(this._repository);

  final RecoveryWordsRepository _repository;

  Future<RecoveryWords> execute() async {
    try {
      return await _repository.getRecoveryWords();
    } catch (e, s) {
      Error.throwWithStackTrace(GetRecoveryWordsException(e), s);
    }
  }
}
