import 'package:matrix/matrix.dart';

final _variationSelectors = RegExp('[︎️]');

/// Reactions that differ only by a variation selector (`❤` and `❤️`) are shown
/// as one reaction, so they are the same reaction here too.
bool _isSameReaction(String emoji, String? reactionKey) =>
    reactionKey != null &&
    emoji.replaceAll(_variationSelectors, '') ==
        reactionKey.replaceAll(_variationSelectors, '');

/// Toggles the current user's reaction on an event.
///
/// - No existing reaction: send [emoji].
/// - Same emoji already reacted (ignoring variation selectors): remove it.
/// - Another emoji reacted: send [emoji], then, only if it was sent, remove
///   all of [myReactions] so a leftover from a failed change goes too.
Future<void> toggleReaction({
  required String emoji,
  required List<Event> myReactions,
  required Future<bool> Function() sendReaction,
}) async {
  if (myReactions.isEmpty) {
    await sendReaction();
    return;
  }
  Future<void> redactMyReactions() =>
      Future.wait(myReactions.map((e) => e.redactEvent()));

  final myReactionKey =
      (myReactions.first.content['m.relates_to'] as Map?)?['key'] as String?;
  if (_isSameReaction(emoji, myReactionKey)) {
    await redactMyReactions();
    return;
  }
  // A redaction synced before the new local echo would empty the row (#2364).
  if (!await sendReaction()) return;
  await redactMyReactions();
}
