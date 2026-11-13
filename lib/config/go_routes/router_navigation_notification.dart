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
    SystemNavigator.setFrameworkHandlesBack(
      notification.canHandlePop || canPop(),
    );
    return true;
  }
}
