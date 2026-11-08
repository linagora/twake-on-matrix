import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/thread/thread_relation_extension.dart';

/// A page of `/relations/<root>?recurse=true&dir=b`: newest first.
typedef ThreadPage = ({List<Event> events, String? nextBatch});

typedef ThreadPageFetcher = Future<ThreadPage> Function(String? from);

/// The events of the thread screen. The SDK has no thread timeline: the
/// replies come from pages going up (`/relations`) completed by the live room
/// timeline, which wins when both have an event.
final class ThreadEvents {
  ThreadEvents({
    required this.rootEventId,
    required this.fetchPage,
    required this.onRelation,
    this.onChanged,
  }) {
    ready = _load().then((_) {}, onError: (_) {});
  }

  final String rootEventId;

  final ThreadPageFetcher fetchPage;

  /// Gets each edit or reaction found in a page, once.
  final void Function(Event event) onRelation;

  /// Called when a page was fetched, or failed.
  final void Function()? onChanged;

  /// Completes once the first page arrived or failed.
  late final Future<void> ready;

  final Map<String, Event> _pageReplies = {};
  final Map<String, Event> _live = {};
  final Set<String> _handedRelations = {};
  Event? _root;
  String? _nextBatch;
  bool _canLoadMore = true;
  Future<void>? _loading;
  List<Event> _events = const [];

  bool get isLoading => _loading != null;

  bool get canLoadMore => _canLoadMore;

  /// Newest first, the root last.
  List<Event> get events => _events;

  /// Fetches the next page; a call during a fetch shares it. Throws when the
  /// page fails: the next call fetches the same page again.
  Future<void> loadMore() {
    final loading = _loading;
    if (loading != null) return loading;
    if (!_canLoadMore) return Future.value();
    final load = _load();
    onChanged?.call();
    return load;
  }

  Future<void> _load() => _loading = _fetch();

  Future<void> _fetch() async {
    try {
      final page = await fetchPage(_nextBatch);
      for (final event in page.events) {
        if (event.threadRootId == rootEventId) {
          _pageReplies[event.eventId] = event;
        } else if (event.relationshipEventId != null &&
            _handedRelations.add(event.eventId)) {
          onRelation(event);
        }
      }
      _nextBatch = page.nextBatch;
      _canLoadMore = page.nextBatch != null;
    } finally {
      _loading = null;
      _rebuild();
      onChanged?.call();
    }
  }

  /// Takes the room timeline (any order) and the root event when known.
  void updateLive(Iterable<Event> timeline, {Event? root}) {
    _root = root;
    for (final event in timeline) {
      // A redacted event lost its relation: it stays a reply once seen.
      if (event.threadRootId == rootEventId ||
          _live.containsKey(event.eventId) ||
          _pageReplies.containsKey(event.eventId)) {
        _live[event.eventId] = event;
      }
    }
    _rebuild();
  }

  /// A deletion seen live of a reply only known from a page.
  void applyRedaction(Event redaction) {
    final id = redaction.redacts;
    final reply = id == null ? null : _pageReplies[id];
    if (reply == null) return;
    _pageReplies[id!] = Event.fromJson(reply.toJson(), reply.room)
      ..setRedactionEvent(redaction);
    _rebuild();
  }

  /// A page reply that was not decryptable and now is.
  void replaceEvent(Event event) {
    if (event.threadRootId != rootEventId ||
        !_pageReplies.containsKey(event.eventId)) {
      return;
    }
    _pageReplies[event.eventId] = event;
    _rebuild();
  }

  /// Page replies that cannot be read yet.
  Iterable<Event> get undecryptedPageReplies =>
      _pageReplies.values.where((e) => e.type == EventTypes.Encrypted);

  void _rebuild() {
    final byId = {..._pageReplies};
    _live.forEach((id, live) {
      // A live copy that cannot be read does not hide a decrypted page copy.
      if (live.type != EventTypes.Encrypted ||
          byId[id]?.type == EventTypes.Encrypted ||
          !byId.containsKey(id)) {
        byId[id] = live;
      }
    });
    final next = [
      ...byId.values.toList()
        ..sort((a, b) => b.originServerTs.compareTo(a.originServerTs)),
      ?_root,
    ];
    if (next.length == _events.length) {
      var same = true;
      for (var i = 0; i < next.length && same; i++) {
        same = identical(next[i], _events[i]);
      }
      if (same) return;
    }
    _events = next;
  }
}
