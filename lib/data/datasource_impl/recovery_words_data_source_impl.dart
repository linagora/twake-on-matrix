import 'package:twake_chat/data/datasource/recovery_words_data_source.dart';
import 'package:twake_chat/data/model/recovery_words_json.dart';
import 'package:twake_chat/data/network/recovery_words/recovery_words_api.dart';
import 'package:twake_chat/domain/model/recovery_words/recovery_words.dart';
import 'package:matrix/matrix.dart';

class RecoveryWordsDataSourceImpl implements RecoveryWordsDataSource {
  const RecoveryWordsDataSourceImpl(this._recoveryWordsAPI);

  final RecoveryWordsAPI _recoveryWordsAPI;

  @override
  Future<RecoveryWords> getRecoveryWords() async {
    try {
      final response = await _recoveryWordsAPI.getRecoveryWords();
      return response.toRecoveryWords();
    } catch (e, s) {
      Logs().w('RecoveryWordsDataSourceImpl::getRecoveryWords()', e, s);
      rethrow;
    }
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
