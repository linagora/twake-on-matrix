import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_privacy_state.freezed.dart';

@freezed
abstract class GroupPrivacyState with _$GroupPrivacyState {
  const GroupPrivacyState._();

  @Assert('!(isPublic && isEncrypted)', 'A public group cannot be encrypted')
  const factory GroupPrivacyState({
    @Default(false) bool isPublic,
    @Default(false) bool isServerLimited,
    @Default(false) bool isEncrypted,
  }) = _GroupPrivacyState;

  bool get canBePublic => !isEncrypted;

  bool get canBeEncrypted => !isPublic;

  /// Unchanged while encrypted; turning public on resets [isServerLimited].
  GroupPrivacyState withPublic({
    required bool isPublic,
    required bool isServerLimitedByDefault,
  }) {
    if (isPublic && !canBePublic) return this;
    return copyWith(
      isPublic: isPublic,
      isServerLimited: isPublic && isServerLimitedByDefault,
    );
  }

  /// Unchanged while public.
  GroupPrivacyState withEncryption({required bool isEncrypted}) {
    if (isEncrypted && !canBeEncrypted) return this;
    return copyWith(isEncrypted: isEncrypted);
  }
}
