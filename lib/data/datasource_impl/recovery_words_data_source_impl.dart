
import 'package:fluffychat/data/datasource/recovery_words_data_source.dart';
import 'package:fluffychat/data/model/recovery_words_json.dart';
import 'package:fluffychat/data/network/recovery_words/recovery_words_api.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';

class RecoveryWordsDataSourceImpl implements RecoveryWordsDataSource {
  final RecoveryWordsAPI _recoveryWordsAPI = getIt.get<RecoveryWordsAPI>();

  @override
  Future<RecoveryWordsResponse> getRecoveryWords() async {
    return _recoveryWordsAPI.getRecoveryWords();
  }

  @override
  Future<bool> saveRecoveryWords(String recoveryWords) async {
    return _recoveryWordsAPI.saveRecoveryWords(recoveryWords);
  }
}