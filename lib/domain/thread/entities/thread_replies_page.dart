/// One page of the replies of a thread. [T] is the reply type of the data
/// source, so the domain stays free of the Matrix SDK.
class ThreadRepliesPage<T> {
  const ThreadRepliesPage({required this.replies, this.nextBatch});

  /// Oldest first. Also holds the edits and reactions of the replies, which
  /// count in the request limit: the screen keeps loading while [canLoadMore].
  final List<T> replies;

  final String? nextBatch;

  bool get canLoadMore => nextBatch != null;
}

/// What to load of a thread: the replies and their edits and reactions, read
/// from `/relations/<root>?recurse=true`.
class ThreadRepliesRequest {
  const ThreadRepliesRequest({
    required this.rootEventId,
    this.from,
    this.limit = defaultPageSize,
  });

  static const int defaultPageSize = 30;

  final String rootEventId;
  final String? from;
  final int limit;
}
