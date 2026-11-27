import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_profile.freezed.dart';

@freezed
abstract class AccountProfile with _$AccountProfile {
  const factory AccountProfile({
    required String userId,
    String? displayName,
    Uri? avatarUrl,
  }) = _AccountProfile;
}
