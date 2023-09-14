import 'package:fluffychat/data/datasource/recovery_words_data_source.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/recovery_words/recovery_words.dart';
import 'package:fluffychat/domain/repository/recovery_words_repository.dart';

class RecoveryWordsRepositoryImpl implements RecoveryWordsRepository {
  final RecoveryWordsDataSource recoveryWordsDataSource =
      getIt.get<RecoveryWordsDataSource>();

  @override
  Future<RecoveryWords> getRecoveryWords() {
    return recoveryWordsDataSource.getRecoveryWords();
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
