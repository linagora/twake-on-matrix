import 'package:twake_chat/domain/media_album/entities/media_album.dart';
import 'package:twake_chat/domain/media_album/entities/media_event_snapshot.dart';

/// Groups images of one send, with the rules of the web client
/// (`groupAlbums`): adjacent, same sender, same batch key, at most a minute
/// apart and on the same day, only the first member may be a reply, only the
/// last may have a caption, and the first unread image starts a new run.
/// A failed image ends the run, so the images on either side of it no longer
/// join (as on the web client).
///
/// Two differences with web: images without a batch key never join (web
/// joins them when they are a minute apart), and images still being sent
/// stay in the run so the album does not break apart while uploading (web
/// joins only sent images).
class GroupMediaEventsPolicy {
  static const int maxAlbumSize = 10;
  static const Duration maxGap = Duration(seconds: 60);

  const GroupMediaEventsPolicy();

  /// [snapshots] are the visible timeline events, oldest first;
  /// [breakBefore] is the first unread event, where a new run starts.
  /// Returns only the runs of two or more images.
  List<MediaAlbum> execute(
    List<MediaEventSnapshot> snapshots, {
    String? breakBefore,
  }) => [
    for (final run in _runs(snapshots, breakBefore))
      if (run.length >= 2)
        MediaAlbum(eventIds: [for (final s in run) s.eventId]),
  ];

  /// Every snapshot is in exactly one run; an image joins the run before it
  /// only if both are album images and the pair passes [_canJoin].
  List<List<MediaEventSnapshot>> _runs(
    List<MediaEventSnapshot> snapshots,
    String? breakBefore,
  ) {
    final runs = <List<MediaEventSnapshot>>[];
    for (final snapshot in snapshots) {
      final run = runs.lastOrNull;
      if (run != null &&
          snapshot.eventId != breakBefore &&
          _canJoin(run, snapshot)) {
        run.add(snapshot);
      } else {
        runs.add([snapshot]);
      }
    }
    return runs;
  }

  bool _isAlbumImage(MediaEventSnapshot s) =>
      s.isImage &&
      !s.isFailed &&
      !s.isRedacted &&
      !s.inThread &&
      s.batchId != null;

  bool _canJoin(List<MediaEventSnapshot> run, MediaEventSnapshot next) {
    final last = run.last;
    return _isAlbumImage(last) &&
        _isAlbumImage(next) &&
        run.length < maxAlbumSize &&
        last.senderId == next.senderId &&
        last.batchId == next.batchId &&
        !last.hasCaption &&
        !next.isReply &&
        next.originServerTs.difference(last.originServerTs) <= maxGap &&
        _sameDay(last.originServerTs, next.originServerTs);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
