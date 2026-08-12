import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/model/recovery_words/recovery_words.dart';

class GetRecoveryWordsSuccess extends Success {
  final RecoveryWords words;

  const GetRecoveryWordsSuccess({required this.words});

  @override
  List<Object?> get props => [words];
}
