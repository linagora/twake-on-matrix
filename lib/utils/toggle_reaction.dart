/// Toggles the current user's reaction on an event.
///
/// - No existing reaction ([redactMyReaction] is null): send [emoji].
/// - Same emoji already reacted: remove it.
/// - Another emoji reacted: remove it, then send [emoji].
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
  await redactMyReaction();
  if (emoji == (myReactionKey ?? '')) return;
  await sendReaction();
}
