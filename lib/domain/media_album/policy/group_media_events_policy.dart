import 'package:twake_chat/domain/media_album/entities/media_album.dart';
import 'package:twake_chat/domain/media_album/entities/media_event_snapshot.dart';

/// Groups images of one send, with the rules of the web client
/// (`groupAlbums`): adjacent, same sender, same batch key, at most a minute
/// apart and on the same day, only the first member may be a reply, only the
/// last may have a caption, and the first unread image starts a new run.
/// A failed image ends the run, so the images on either side of it no longer
/// join (as on the web client). A deleted event between two images of a run
/// does not: it is hidden in the album, so deleting an image reflows it.
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
      if (run.images.length >= 2)
        MediaAlbum(
          eventIds: [for (final s in run.images) s.eventId],
          hiddenEventIds: [for (final s in run.deleted) s.eventId],
        ),
  ];

  /// Every snapshot is in exactly one run; an image joins the run before it
  /// only if both are album images and the pair passes [_canJoin]. Deleted
  /// events of the run's sender wait: they join as hidden members if the
  /// next image joins, and stand alone otherwise. The first unread event
  /// never waits: it starts a new run even when deleted.
  List<_Run> _runs(List<MediaEventSnapshot> snapshots, String? breakBefore) {
    final runs = <_Run>[];
    final waiting = <MediaEventSnapshot>[];
    for (final snapshot in snapshots) {
      final run = runs.lastOrNull;
      if (run != null &&
          snapshot.eventId != breakBefore &&
          _mayHide(run, snapshot)) {
        waiting.add(snapshot);
        continue;
      }
      if (run != null &&
          snapshot.eventId != breakBefore &&
          _canJoin(run.images, snapshot)) {
        run.deleted.addAll(waiting);
        run.images.add(snapshot);
      } else {
        runs.addAll(waiting.map(_Run.single));
        runs.add(_Run.single(snapshot));
      }
      waiting.clear();
    }
    runs.addAll(waiting.map(_Run.single));
    return runs;
  }

  /// A deleted event right after an album image of the same sender may be a
  /// deleted image of that album: Matrix strips its content, batch key
  /// included, so only its place tells.
  bool _mayHide(_Run run, MediaEventSnapshot next) =>
      next.isRedacted &&
      _isAlbumImage(run.images.last) &&
      next.senderId == run.images.last.senderId;

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

/// The images of one run and the deleted events hidden between them.
class _Run {
  final List<MediaEventSnapshot> images;
  final List<MediaEventSnapshot> deleted = [];

  _Run.single(MediaEventSnapshot first) : images = [first];
}
