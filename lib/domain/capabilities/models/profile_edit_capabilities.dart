import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_edit_capabilities.freezed.dart';

@freezed
abstract class ProfileEditCapabilities with _$ProfileEditCapabilities {
  const factory ProfileEditCapabilities({
    required bool canEditAvatar,
    required bool canEditDisplayName,
  }) = _ProfileEditCapabilities;
}
