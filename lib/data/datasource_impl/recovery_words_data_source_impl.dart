import 'package:twake_chat/data/datasource/recovery_words_data_source.dart';
import 'package:twake_chat/data/model/recovery_words_json.dart';
import 'package:twake_chat/data/network/recovery_words/recovery_words_api.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/model/recovery_words/recovery_words.dart';

class RecoveryWordsDataSourceImpl implements RecoveryWordsDataSource {
  final RecoveryWordsAPI _recoveryWordsAPI = getIt.get<RecoveryWordsAPI>();

  @override
  Future<RecoveryWords> getRecoveryWords() {
    return _recoveryWordsAPI.getRecoveryWords().then(
      (response) => response.toRecoveryWords(),
    );
  }

  @override
  Future<bool> saveRecoveryWords(String recoveryWords) async {
    return _recoveryWordsAPI.saveRecoveryWords(recoveryWords);
  }

  @override
  Future<bool> deleteRecoveryWords() {
    return _recoveryWordsAPI.deleteRecoveryWords();
  }
}
