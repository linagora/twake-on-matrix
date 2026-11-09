import 'package:matrix/matrix.dart';

final _variationSelectors = RegExp('[\uFE0E\uFE0F]');

/// Reactions that differ only by a variation selector (`❤` and `❤️`) are shown
/// as one reaction, so they are the same reaction here too.
bool _isSameReaction(String emoji, String? reactionKey) =>
    reactionKey != null &&
    emoji.replaceAll(_variationSelectors, '') ==
        reactionKey.replaceAll(_variationSelectors, '');

String? _keyOf(Event reaction) => reaction.content
    .tryGetMap<String, Object?>('m.relates_to')
    ?.tryGet<String>('key');

/// Toggles the current user's reaction on an event.
///
/// - One of [myReactions] still sending: ignore the tap, its echo has no
///   event id to redact yet.
/// - No sent reaction: send [emoji].
/// - Same emoji already reacted (ignoring variation selectors): remove it,
///   and keep my other reactions.
/// - Another emoji: send [emoji], then, only if it was sent, remove all my
///   sent reactions so a leftover from a failed change goes too.
///
/// Once [emoji] is sent, my reactions whose send failed are dropped.
Future<void> toggleReaction({
  required String emoji,
  required List<Event> myReactions,
  required Future<bool> Function() sendReaction,
}) async {
  if (myReactions.any((e) => e.status.isSending)) return;
  final sent = myReactions.where((e) => e.status.isSent).toList();
  final failed = myReactions.where((e) => e.status.isError).toList();
  if (sent.isEmpty) {
    if (await sendReaction()) {
      await Future.wait(failed.map((e) => e.cancelSend()));
    }
    return;
  }
  final same = sent.where((e) => _isSameReaction(emoji, _keyOf(e)));
  if (same.isNotEmpty) {
    await Future.wait(same.map((e) => e.redactEvent()));
    return;
  }
  // A redaction synced before the new local echo would empty the row (#2364).
  if (!await sendReaction()) return;
  await Future.wait([
    ...sent.map((e) => e.redactEvent()),
    ...failed.map((e) => e.cancelSend()),
  ]);
}
