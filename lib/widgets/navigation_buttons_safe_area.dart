import 'package:flutter/material.dart';
import 'package:twake_chat/utils/android_utils.dart';

class NavigationButtonsSafeArea extends StatelessWidget {
  final Widget? child;

  const NavigationButtonsSafeArea({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final child = this.child ?? const SizedBox.shrink();
    if (!AndroidUtils.isNavigationButtonsEnabled(
      systemGestureInsets: MediaQuery.systemGestureInsetsOf(context),
    )) {
      return child;
    }
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(top: false, left: false, right: false, child: child),
    );
  }
}
