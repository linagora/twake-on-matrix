import 'package:fluffychat/widgets/twake_components/twake_navigation_icon/twake_navigation_icon_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class TwakeNavigationIcon extends StatelessWidget {
  final IconData icon;
  final int notificationCount;
  final bool isSelected;
  final Color? color;

  const TwakeNavigationIcon({
    super.key,
    required this.icon,
    this.notificationCount = 0,
    this.isSelected = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Badge(
      backgroundColor: Theme.of(context).colorScheme.error,
      isLabelVisible: notificationCount > 0,
      largeSize: TwakeNavigationIconStyle.badgeHeight,
      label: Text(
        notificationCount.toString(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      child: Icon(
        icon,
        color: isSelected
            ? LinagoraSysColors.material().primary
            : color ?? Theme.of(context).iconTheme.color,
      ),
    );
  }
}
