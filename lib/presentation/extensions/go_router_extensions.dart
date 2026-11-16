import 'package:go_router/go_router.dart';

extension GoRouterExtensions on GoRouter {
  String? get activeRoomId {
    try {
      final path = routeInformationProvider.value.uri.path;
      if (path.isEmpty) return null;
      if (!path.startsWith('/rooms/')) return null;
      // A thread screen hides the main timeline of the room: its messages
      // must still notify; the open thread is exposed by [activeThread].
      if (path.contains('/threads/')) return null;
      return path.split('/')[2];
    } catch (e) {
      return null;
    }
  }

  /// The thread open on screen (`/rooms/R/threads/T`), if any. Only the
  /// events of this thread are read live, so only they skip a notification.
  ({String roomId, String threadRootId})? get activeThread {
    try {
      final segments = routeInformationProvider.value.uri.pathSegments;
      if (segments.length < 4 ||
          segments[0] != 'rooms' ||
          segments[2] != 'threads') {
        return null;
      }
      return (roomId: segments[1], threadRootId: segments[3]);
    } catch (e) {
      return null;
    }
  }
}
