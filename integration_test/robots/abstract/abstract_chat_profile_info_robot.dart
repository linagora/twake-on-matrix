import 'package:fluffychat/presentation/enum/profile_info/profile_info_body_enum.dart';

/// Platform-agnostic contract for the member profile-info screen.
abstract class AbstractChatProfileInfoRobot {
  Future<String> getDisplayName();
  Future<String> getEmail();
  Future<String> getPhoneNumber();

  Future<void> verifyDisplayName({required String displayName});
  Future<void> verifyDisplayMatrixId({required String matrixId});
  Future<void> verifyEmail({required String email});
  Future<void> verifyPhoneNumber({required String phoneNumber});

  Future<void> verifyProfileActionButtonVisible(
    ProfileInfoActions action, {
    bool expected = true,
  });
  Future<void> tapProfileActionButton(ProfileInfoActions action);
  Future<void> confirmTransferOwnership();
}
