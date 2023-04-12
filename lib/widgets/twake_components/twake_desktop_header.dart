import 'package:fluffychat/utils/custom_svg_icons.dart';
import 'package:flutter/material.dart';


import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/client_chooser_button.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class TwakeDesktopHeader extends StatelessWidget implements PreferredSizeWidget {
  final ChatListController controller;

  const TwakeDesktopHeader({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      toolbarHeight: 52.0,
      automaticallyImplyLeading: false,
      leadingWidth: 200,
      leading: SizedBox(
        width: 0,
        child: ClientChooserButton(controller, titleString: L10n.of(context)!.directMessages),
      ),
      actions: [
        SvgPicture.asset(
          CustomSVGIcons.settingsIcon,
          color: Theme.of(context).colorScheme.primary,
          width: 28,
          height: 28,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 12.0),
          child: SvgPicture.asset(
            CustomSVGIcons.editIcon,
            color: Theme.of(context).colorScheme.primary,
            width: 28,
            height: 28,
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(52);
}
