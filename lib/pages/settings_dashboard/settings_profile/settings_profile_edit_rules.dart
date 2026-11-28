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

  /// The field follows a new profile name unless the user edited it.
  static bool shouldSyncName({
    required String text,
    required String shownName,
  }) => editedDisplayName(text: text, currentName: shownName) == null;
}
