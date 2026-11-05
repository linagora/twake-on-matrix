final _variationSelectors = RegExp('[\uFE0E\uFE0F]');

/// Reactions that differ only by a variation selector (`❤` and `❤️`) are shown
/// as one reaction, so they are the same reaction here too.
bool _isSameReaction(String emoji, String? reactionKey) =>
    reactionKey != null &&
    emoji.replaceAll(_variationSelectors, '') ==
        reactionKey.replaceAll(_variationSelectors, '');

/// Toggles the current user's reaction on an event.
///
/// - No existing reaction ([redactMyReaction] is null): send [emoji].
/// - Same emoji already reacted (ignoring variation selectors): remove it.
/// - Another emoji reacted: send [emoji], then remove the old one.
Future<void> toggleReaction({
  required String emoji,
  required String? myReactionKey,
  required Future<void> Function()? redactMyReaction,
  required Future<void> Function() sendReaction,
}) async {
  if (redactMyReaction == null) {
    await sendReaction();
    return;
  }
  if (_isSameReaction(emoji, myReactionKey)) {
    await redactMyReaction();
    return;
  }
  // A redaction synced before the new local echo would empty the row (#2364).
  await sendReaction();
  await redactMyReaction();
}
