import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_state_layer.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

import '../../pages/contacts_tab/contacts_appbar_style.dart';

class TwakeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool withDivider;
  final BuildContext context;
  final Widget? leading;
  final bool? centerTitle;
  final List<Widget>? actions;
  final Color? backgroundColor;

  const TwakeAppBar({
    super.key,
    required this.title,
    required this.context,
    this.withDivider = false,
    this.leading,
    this.centerTitle,
    this.actions,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor:
          backgroundColor ?? TwakeAppBarStyle.appBarBackgroundColor(context),
      toolbarHeight: AppConfig.toolbarHeight(context),
      centerTitle:
          centerTitle ?? TwakeAppBarStyle.responsiveUtils.isMobile(context),
      automaticallyImplyLeading: false,
      leading: leading,
      title: Column(
        children: [
          Padding(
            padding: centerTitle == true
                ? EdgeInsets.zero
                : ContactsAppbarStyle.titlePadding(context),
            child: Text(
              title,
              style: TwakeAppBarStyle.titleTextStyle(context),
            ),
          ),
        ],
      ),
      actions: actions,
      bottom: withDivider
          ? PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: TwakeAppBarStyle.dividerHeight,
                thickness: TwakeAppBarStyle.dividerthickness,
                color: LinagoraStateLayer(
                  LinagoraSysColors.material().surfaceTint,
                ).opacityLayer3,
              ),
            )
          : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(AppConfig.toolbarHeight(context));
}
