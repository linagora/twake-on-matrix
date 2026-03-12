import 'package:fluffychat/config/app_config.dart';
import 'package:flutter/material.dart';

/// Shared badge widget for displaying unread message count.
/// Used in chat list items and chat view scroll-down FAB.
class UnreadCountBadge extends StatelessWidget {
  final int count;
  final Color backgroundColor;
  final TextStyle? textStyle;

  /// Max count before showing "99+"
  static const int maxDisplayCount = 99;

  const UnreadCountBadge({
    super.key,
    required this.count,
    required this.backgroundColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final displayText = count > maxDisplayCount
        ? '$maxDisplayCount+'
        : '$count';
    final defaultTextStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      letterSpacing: -0.5,
      color: Theme.of(context).colorScheme.onPrimary,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(displayText, style: textStyle ?? defaultTextStyle),
      ),
    );
  }
}
