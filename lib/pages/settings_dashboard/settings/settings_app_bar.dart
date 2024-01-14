import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;

  final BuildContext context;

  final List<Widget>? actions;

  const SettingsAppBar({
    super.key,
    required this.title,
    required this.context,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveUtils = getIt.get<ResponsiveUtils>();
    return AppBar(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      title: title,
      leading: responsiveUtils.isMobile(context)
          ? const BackButton()
          : const SizedBox.shrink(),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(AppConfig.toolbarHeight(context));
}
