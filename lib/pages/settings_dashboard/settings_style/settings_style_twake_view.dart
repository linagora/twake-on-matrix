import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class SettingsStyleTwakeView extends StatelessWidget {
  const SettingsStyleTwakeView({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sysColors = LinagoraSysColors.material();
    return Container(
      color: sysColors.surfaceVariant,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.topCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: sysColors.onPrimary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      ),
    );
  }
}
