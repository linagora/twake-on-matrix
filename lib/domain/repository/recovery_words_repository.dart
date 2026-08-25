import 'package:twake_chat/domain/model/recovery_words/recovery_words.dart';

abstract class RecoveryWordsRepository {
  Future<RecoveryWords> getRecoveryWords();

  Future<bool> saveRecoveryWords(String recoveryWords);

  Future<bool> deleteRecoveryWords();
}
