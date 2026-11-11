import 'package:matrix/matrix.dart';
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
  final Set<String> _hiddenIds;

  AlbumTimelineIndex._(
    this._visibleNewestFirst,
    this._position,
    this._albumByLeader,
    this._hiddenIds,
  );

  /// [visibleNewestFirst] is the visible events, newest first; [breakBefore]
  /// is the first unread event, which starts a new album.
  factory AlbumTimelineIndex(
    List<Event> visibleNewestFirst, {
    String? breakBefore,
  }) {
    final oldestFirst = visibleNewestFirst.reversed.toList();
    final byId = {for (final e in oldestFirst) e.eventId: e};
    final albums = const GroupMediaEventsPolicy().execute([
      for (final e in oldestFirst) e.toMediaSnapshotIfBatched(),
    ], breakBefore: breakBefore);
    return AlbumTimelineIndex._(
      visibleNewestFirst,
      _positions(visibleNewestFirst),
      _albumsByLeader(albums, byId),
      _hiddenMembers(albums),
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

  static Set<String> _hiddenMembers(List<MediaAlbum> albums) => {
    for (final a in albums) ...a.eventIds.where((id) => id != a.leaderEventId),
  };

  /// The images of the album that [eventId] leads, oldest first, else null.
  List<Event>? albumLedBy(String eventId) => _albumByLeader[eventId];

  /// True for an album image that the leader draws.
  bool isHiddenMember(String eventId) => _hiddenIds.contains(eventId);

  /// The leader that draws the hidden image [eventId], else null (the event
  /// is drawn on its own row).
  String? albumLeaderOf(String eventId) {
    if (!isHiddenMember(eventId)) return null;
    for (final entry in _albumByLeader.entries) {
      if (entry.value.any((event) => event.eventId == eventId)) {
        return entry.key;
      }
    }
    return null;
  }

  /// The newer neighbour. For a leader it is the event newer than the newest
  /// image of its album, not another image of it.
  Event? newerNeighbour(Event event) {
    final position = _position[event.eventId];
    if (position == null) return null;
    final members = _albumByLeader[event.eventId];
    final index = position - 1 - (members == null ? 0 : members.length - 1);
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
