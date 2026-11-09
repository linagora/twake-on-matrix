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
/// - One of [myReactions] still sending: ignore the tap, its echo has no
///   event id to redact yet.
/// - No sent reaction: send [emoji].
/// - Same emoji already reacted (ignoring variation selectors): remove it,
///   and keep my other reactions.
/// - Another emoji: send [emoji], then, only if it was sent, remove all my
///   sent reactions so a leftover from a failed change goes too.
Future<void> toggleReaction({
  required String emoji,
  required List<Event> myReactions,
  required Future<bool> Function() sendReaction,
}) async {
  if (myReactions.any((e) => e.status.isSending)) return;
  final sent = myReactions.where((e) => e.status.isSent).toList();
  if (sent.isEmpty) {
    await sendReaction();
    return;
  }
  final same = sent.where((e) => _isSameReaction(emoji, _keyOf(e)));
  if (same.isNotEmpty) {
    await Future.wait(same.map((e) => e.redactEvent()));
    return;
  }
  // A redaction synced before the new local echo would empty the row (#2364).
  if (!await sendReaction()) return;
  await Future.wait(sent.map((e) => e.redactEvent()));
}
