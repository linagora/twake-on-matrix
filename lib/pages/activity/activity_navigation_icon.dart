import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/domain/activity/usecases/watch_unread_mention_count_use_case.provider.dart';
import 'package:twake_chat/widgets/twake_components/twake_navigation_icon/twake_navigation_icon.dart';

/// The icon of the Activity tab, badged with the unread mentions count.
class ActivityNavigationIcon extends ConsumerWidget {
  const ActivityNavigationIcon({
    super.key,
    this.color,
    this.isSelected = false,
    this.icon = Icons.notifications_outlined,
  });

  final Color? color;
  final bool isSelected;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TwakeNavigationIcon(
    icon: icon,
    notificationCount: ref.watch(unreadMentionCountProvider).value ?? 0,
    isSelected: isSelected,
    color: color,
  );
}
