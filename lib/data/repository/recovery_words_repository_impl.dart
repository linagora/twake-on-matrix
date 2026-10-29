import 'package:twake_chat/data/datasource/recovery_words_data_source.dart';
import 'package:twake_chat/domain/model/recovery_words/recovery_words.dart';
import 'package:twake_chat/domain/repository/recovery_words_repository.dart';
import 'package:matrix/matrix.dart';

class RecoveryWordsRepositoryImpl implements RecoveryWordsRepository {
  const RecoveryWordsRepositoryImpl(this.recoveryWordsDataSource);

  final RecoveryWordsDataSource recoveryWordsDataSource;

  @override
  Future<RecoveryWords> getRecoveryWords() async {
    try {
      return await recoveryWordsDataSource.getRecoveryWords();
    } catch (e, s) {
      Logs().wtf('RecoveryWordsRepositoryImpl::getRecoveryWords()', e, s);
      rethrow;
    }
  }

  @override
  Future<bool> saveRecoveryWords(String recoveryWords) async {
    return await recoveryWordsDataSource.saveRecoveryWords(recoveryWords);
  }

  @override
  Future<bool> deleteRecoveryWords() async {
    return await recoveryWordsDataSource.deleteRecoveryWords();
  }
}
