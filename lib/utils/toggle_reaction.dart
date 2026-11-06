import 'package:matrix/matrix.dart';

final _variationSelectors = RegExp('[\uFE0E\uFE0F]');

/// Reactions that differ only by a variation selector (`❤` and `❤️`) are shown
/// as one reaction, so they are the same reaction here too.
bool _isSameReaction(String emoji, String? reactionKey) =>
    reactionKey != null &&
    emoji.replaceAll(_variationSelectors, '') ==
        reactionKey.replaceAll(_variationSelectors, '');

String? _keyOf(Event reaction) =>
    (reaction.content['m.relates_to'] as Map?)?['key'] as String?;

/// Toggles the current user's reaction on an event.
///
/// - No existing reaction: send [emoji].
/// - Same emoji already reacted (ignoring variation selectors): remove all of
///   [myReactions].
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

  if (myReactions.any((e) => _isSameReaction(emoji, _keyOf(e)))) {
    await redactMyReactions();
    return;
  }
  // A redaction synced before the new local echo would empty the row (#2364).
  if (!await sendReaction()) return;
  await redactMyReactions();
}
