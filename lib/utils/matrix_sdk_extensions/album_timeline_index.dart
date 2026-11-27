import 'package:matrix/matrix.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/domain/media_album/entities/media_album.dart';
import 'package:twake_chat/domain/media_album/policy/group_media_events_policy.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_to_media_snapshot_extension.dart';

/// The albums of the visible timeline and the neighbours of each event, with
/// an album counted as one message.
///
/// The leader (the oldest image) draws the album; every other image keeps its
/// own empty slot in the list so that indexes and scroll-to keys do not move.
class AlbumTimelineIndex {
  final List<Event> _visibleNewestFirst;
  final Map<String, int> _position;
  final Map<String, List<Event>> _albumByLeader;

  /// Every event that a leader stands for, mapped to that leader.
  final Map<String, String> _leaderByHidden;

  /// How many timeline events each leader stands for: its album with the
  /// deleted images hidden in it.
  final Map<String, int> _spanByLeader;

  AlbumTimelineIndex._(
    this._visibleNewestFirst,
    this._albumByLeader,
    this._leaderByHidden,
    this._spanByLeader,
  ) : _position = _positions(_visibleNewestFirst);

  /// [visibleNewestFirst] is the visible events, newest first; [breakBefore]
  /// is the first unread event, which starts a new album. [threadRootIds]
  /// are the images known as thread roots only from live replies (no server
  /// summary yet): like any thread root, they leave the album.
  factory AlbumTimelineIndex(
    List<Event> visibleNewestFirst, {
    String? breakBefore,
    Set<String> threadRootIds = const {},
  }) {
    final oldestFirst = visibleNewestFirst.reversed.toList();
    final byId = {for (final e in oldestFirst) e.eventId: e};
    final snapshots = [
      for (final e in oldestFirst)
        e.toMediaSnapshotIfBatched(
          isThreadRoot:
              AppConfig.threadsEnabled && threadRootIds.contains(e.eventId),
        ),
    ];
    final albums = const GroupMediaEventsPolicy().execute(
      snapshots,
      breakBefore: breakBefore,
    );
    return AlbumTimelineIndex._(
      visibleNewestFirst,
      _albumsByLeader(albums, byId),
      _hiddenMembers(albums),
      _albumSpans(albums),
    );
  }

  static Map<String, int> _positions(List<Event> events) => {
    for (var i = 0; i < events.length; i++) events[i].eventId: i,
  };

  static Map<String, List<Event>> _albumsByLeader(
    List<MediaAlbum> albums,
    Map<String, Event> byId,
  ) => {
    for (final a in albums)
      a.leaderEventId: [for (final id in a.eventIds) byId[id]!],
  };

  static Map<String, String> _hiddenMembers(List<MediaAlbum> albums) => {
    for (final a in albums)
      for (final id in [...a.eventIds, ...a.hiddenEventIds])
        if (id != a.leaderEventId) id: a.leaderEventId,
  };

  static Map<String, int> _albumSpans(List<MediaAlbum> albums) => {
    for (final a in albums)
      a.leaderEventId: a.eventIds.length + a.hiddenEventIds.length,
  };

  /// The images of the album that [eventId] leads, oldest first, else null.
  List<Event>? albumLedBy(String eventId) => _albumByLeader[eventId];

  /// True for an event that a leader stands for: an album image it draws or
  /// a deleted image hidden in its album.
  bool isHiddenMember(String eventId) => _leaderByHidden.containsKey(eventId);

  /// The leader that draws the hidden event [eventId] (an album image or a
  /// deleted image hidden in an album), else null (the event is drawn on its
  /// own row).
  String? albumLeaderOf(String eventId) => _leaderByHidden[eventId];

  /// The newer neighbour. For a leader it is the event newer than everything
  /// it stands for, not one of those events.
  Event? newerNeighbour(Event event) {
    final position = _position[event.eventId];
    if (position == null) return null;
    final span = _spanByLeader[event.eventId] ?? 1;
    final index = position - span;
    return index >= 0 ? _visibleNewestFirst[index] : null;
  }

  /// The older neighbour.
  Event? olderNeighbour(Event event) {
    final position = _position[event.eventId];
    if (position == null || position + 1 >= _visibleNewestFirst.length) {
      return null;
    }
    return _visibleNewestFirst[position + 1];
  }
}
