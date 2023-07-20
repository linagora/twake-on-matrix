import 'package:equatable/equatable.dart';
import 'package:fluffychat/domain/model/recovery_words/recovery_words.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recovery_words_json.g.dart';

@JsonSerializable()
class RecoveryWordsResponse with EquatableMixin {
  @JsonKey(name: 'words')
  final String? words;

  RecoveryWordsResponse({
    this.words,
  });

  factory RecoveryWordsResponse.fromJson(Map<String, dynamic> json) =>
      _$RecoveryWordsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RecoveryWordsResponseToJson(this);

  @override
  List<Object?> get props => [words];
}

extension RecoveryWordsResponseExtension on RecoveryWordsResponse {
  RecoveryWords toRecoveryWords() => RecoveryWords(words!);
}
