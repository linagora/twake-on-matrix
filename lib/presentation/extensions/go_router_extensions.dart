import 'package:go_router/go_router.dart';

extension GoRouterExtensions on GoRouter {
  String? get activeRoomId {
    try {
      final path = routeInformationProvider.value.uri.path;
      if (path.isEmpty) return null;
      if (!path.startsWith('/rooms/')) return null;
      return path.split('/')[2];
    } catch (e) {
      return null;
    }
  }
}
