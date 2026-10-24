import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/contact/datasources/matrix_profile_datasource.dart';
import 'package:twake_chat/presentation/extensions/contact/matrix_user_profile_extension.dart';

abstract final class SettingsProfileEditRules {
  static String? editedDisplayName({
    required String text,
    required String currentName,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed == currentName) return null;
    return trimmed;
  }

  static bool hasChanges({
    required String text,
    required String currentName,
    required bool hasPendingAvatar,
  }) =>
      editedDisplayName(text: text, currentName: currentName) != null ||
      hasPendingAvatar;

  /// A failed fresh read right after a save must not replace the saved profile
  /// with an id-only one.
  static Profile? reloadedProfile({
    required MatrixUserProfile? fetched,
    required String userId,
    required bool fresh,
  }) {
    if (fetched == null && fresh) return null;
    return fetched.toProfile(userId);
  }

  static bool shouldOverwriteName({
    required String textBeforeRead,
    required String textAfterRead,
    required bool hadUnsavedEditBeforeRead,
  }) => !hadUnsavedEditBeforeRead && textAfterRead == textBeforeRead;
}
