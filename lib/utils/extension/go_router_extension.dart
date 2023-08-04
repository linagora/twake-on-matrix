import 'package:go_router/go_router.dart';

// API for get current route data
// Ref: https://github.com/flutter/flutter/issues/110858
extension GoRouterExtension on GoRouter {
  Map<String, String> get currentPathParameters {
    final lastMatch = routerDelegate.currentConfiguration.last;
    final matchList = lastMatch is ImperativeRouteMatch ? lastMatch.matches : routerDelegate.currentConfiguration;
    return matchList.pathParameters;
  }
}