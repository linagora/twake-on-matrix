import 'package:fluffychat/data/model/recovery_words_json.dart';

abstract class RecoveryWordsDataSource {
  Future<RecoveryWordsResponse> getRecoveryWords();

  Future<bool> saveRecoveryWords(String recoveryWords);
}