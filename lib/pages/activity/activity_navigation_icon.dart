import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/providers/activity_providers.dart';
import 'package:twake_chat/widgets/twake_components/twake_navigation_icon/twake_navigation_icon.dart';

/// The icon of the Activity tab, badged with the unread mentions count.
class ActivityNavigationIcon extends ConsumerWidget {
  const ActivityNavigationIcon({
    super.key,
    this.color,
    this.isSelected = false,
  });

  final Color? color;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TwakeNavigationIcon(
    icon: Icons.notifications_outlined,
    notificationCount: ref.watch(unreadMentionCountProvider).value ?? 0,
    isSelected: isSelected,
    color: color,
  );
}
