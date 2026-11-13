/// One page of the replies of a thread. [T] is the reply type of the data
/// source, so the domain stays free of the Matrix SDK.
class ThreadRepliesPage<T> {
  const ThreadRepliesPage({required this.replies, this.nextBatch});

  /// Oldest first.
  final List<T> replies;

  final String? nextBatch;

  bool get canLoadMore => nextBatch != null;
}

/// What to load of a thread.
///
/// [withRelations]: the thread screen also needs the edits and reactions of
/// the replies, so it reads `/relations/<root>?recurse=true` with no
/// `rel_type` filter (they come in [ThreadRepliesPage.replies] too); without
/// it, `/relations/<root>/m.thread` gives the replies only.
/// [decrypt]: false when only ids are read (mark as read).
class ThreadRepliesRequest {
  const ThreadRepliesRequest({
    required this.rootEventId,
    this.from,
    this.limit = defaultPageSize,
    this.withRelations = false,
    this.decrypt = true,
  });

  static const int defaultPageSize = 30;

  final String rootEventId;
  final String? from;
  final int limit;
  final bool withRelations;
  final bool decrypt;
}
