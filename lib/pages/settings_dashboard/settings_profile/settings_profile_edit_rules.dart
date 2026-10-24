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
  static bool keepsSavedProfile({
    required bool readFailed,
    required bool fresh,
  }) => readFailed && fresh;

  static bool shouldOverwriteName({
    required String textBeforeRead,
    required String textAfterRead,
    required bool hadUnsavedEditBeforeRead,
  }) => !hadUnsavedEditBeforeRead && textAfterRead == textBeforeRead;
}
