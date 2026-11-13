import 'package:twake_chat/domain/media_album/entities/media_event_snapshot.dart';
import 'package:twake_chat/domain/media_album/policy/group_media_events_policy.dart';

/// Collapses deleted messages that follow each other: same sender, at most a
/// minute apart, on the same day. Deleting a whole album then leaves one
/// "Deleted message" instead of one per image. Matrix strips the content of
/// a deleted event, so this cannot tell an image from a text: deleted texts
/// sent together collapse too.
class CollapseDeletedEventsPolicy {
  const CollapseDeletedEventsPolicy();

  /// [snapshots] are the visible timeline events, oldest first. Returns each
  /// run of two or more deleted events, oldest first; the oldest one stays
  /// visible and stands for the others. [breakBefore] is the first unread
  /// event, which starts a new run so its unread marker stays visible.
  List<List<String>> execute(
    List<MediaEventSnapshot> snapshots, {
    String? breakBefore,
  }) {
    final runs = <List<MediaEventSnapshot>>[];
    MediaEventSnapshot? previous;
    for (final snapshot in snapshots) {
      if (!snapshot.isRedacted) {
        previous = null;
        continue;
      }
      if (snapshot.eventId != breakBefore && _follows(previous, snapshot)) {
        runs.last.add(snapshot);
      } else {
        runs.add([snapshot]);
      }
      previous = snapshot;
    }
    return _collapsed(runs);
  }

  List<List<String>> _collapsed(List<List<MediaEventSnapshot>> runs) => [
    for (final run in runs)
      if (run.length >= 2) [for (final s in run) s.eventId],
  ];

  bool _follows(MediaEventSnapshot? previous, MediaEventSnapshot next) =>
      previous != null &&
      previous.senderId == next.senderId &&
      next.originServerTs.difference(previous.originServerTs) <=
          GroupMediaEventsPolicy.maxGap &&
      previous.originServerTs.day == next.originServerTs.day;
}
