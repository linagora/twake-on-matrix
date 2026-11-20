import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension RouterNavigationNotification on GoRouter {
  // A dialog sits on a navigator above the router's, which reports nothing to pop once it closes.
  bool onNavigationNotification(NavigationNotification notification) {
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (lifecycleState == null ||
        lifecycleState == AppLifecycleState.detached) {
      return true;
    }
    final canHandlePop = notification.canHandlePop || canPop();
    final innermostNavigatorContext = _innermostNavigator?.overlay?.context;
    if (canHandlePop ||
        notification is _InnermostNavigatorCheck ||
        innermostNavigatorContext == null) {
      SystemNavigator.setFrameworkHandlesBack(canHandlePop);
      return true;
    }
    // Each navigator on the way up answers again, a page whose PopScope keeps Back included.
    const _InnermostNavigatorCheck().dispatch(innermostNavigatorContext);
    return true;
  }

  NavigatorState? get _innermostNavigator {
    var navigatorKey = routerDelegate.navigatorKey;
    final matches = routerDelegate.currentConfiguration.matches;
    if (matches.isEmpty) return navigatorKey.currentState;
    var walker = matches.last;
    while (walker is ShellRouteMatch) {
      navigatorKey = walker.navigatorKey;
      walker = walker.matches.last;
    }
    return navigatorKey.currentState;
  }
}

class _InnermostNavigatorCheck extends NavigationNotification {
  const _InnermostNavigatorCheck() : super(canHandlePop: false);
}
