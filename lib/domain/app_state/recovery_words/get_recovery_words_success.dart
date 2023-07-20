import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/model/recovery_words/recovery_words.dart';

class GetRecoveryWordsSuccess extends Success {
  final RecoveryWords words;

  const GetRecoveryWordsSuccess({required this.words});

  @override
  List<Object?> get props => [words];
}
