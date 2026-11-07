import 'package:go_router/go_router.dart';

extension GoRouterExtensions on GoRouter {
  String? get activeRoomId {
    try {
      final path = routeInformationProvider.value.uri.path;
      if (path.isEmpty) return null;
      if (!path.startsWith('/rooms/')) return null;
      // A thread screen hides the main timeline of the room: its messages
      // must still notify (the thread's own replies notify too, a lesser harm
      // than losing the room's).
      if (path.contains('/threads/')) return null;
      return path.split('/')[2];
    } catch (e) {
      return null;
    }
  }
}
