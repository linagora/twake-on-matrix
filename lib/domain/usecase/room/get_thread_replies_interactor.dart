import 'package:matrix/matrix.dart';

class ThreadRepliesPage {
  const ThreadRepliesPage({required this.replies, this.nextBatch});

  /// Oldest first.
  final List<Event> replies;

  final String? nextBatch;

  bool get canLoadMore => nextBatch != null;
}

/// Loads the replies of a thread by pages, going up its history
/// (`/relations/<root>/m.thread`).
final class GetThreadRepliesInteractor {
  const GetThreadRepliesInteractor();

  static const int pageSize = 30;

  Future<ThreadRepliesPage> execute({
    required Room room,
    required String rootEventId,
    String? from,
  }) async {
    final response = await room.client.getRelatingEventsWithRelType(
      room.id,
      rootEventId,
      RelationshipTypes.thread,
      from: from,
      limit: pageSize,
      dir: Direction.b,
    );
    return ThreadRepliesPage(
      replies: [
        for (final event in response.chunk.reversed)
          Event.fromMatrixEvent(event, room),
      ],
      nextBatch: response.nextBatch,
    );
  }
}
