import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_privacy_state.freezed.dart';

@freezed
abstract class GroupPrivacyState with _$GroupPrivacyState {
  const factory GroupPrivacyState({
    @Default(false) bool isPublic,
    @Default(false) bool isServerLimited,
  }) = _GroupPrivacyState;
}
