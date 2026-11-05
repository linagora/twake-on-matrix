import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_privacy_state.freezed.dart';

@freezed
abstract class GroupPrivacyState with _$GroupPrivacyState {
  const GroupPrivacyState._();

  @Assert('!(isPublic && isEncrypted)', 'A public group cannot be encrypted')
  const factory GroupPrivacyState({
    @Default(false) bool isPublic,
    @Default(false) bool isEncrypted,
  }) = _GroupPrivacyState;

  bool get canBePublic => !isEncrypted;

  bool get canBeEncrypted => !isPublic;

  /// Unchanged while encrypted.
  GroupPrivacyState withPublic({required bool isPublic}) {
    if (isPublic && !canBePublic) return this;
    return copyWith(isPublic: isPublic);
  }

  /// Unchanged while public.
  GroupPrivacyState withEncryption({required bool isEncrypted}) {
    if (isEncrypted && !canBeEncrypted) return this;
    return copyWith(isEncrypted: isEncrypted);
  }
}
