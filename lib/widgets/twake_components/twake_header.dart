import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/client_chooser_button.dart';
import 'package:fluffychat/utils/custom_svg_icons.dart';
import 'package:fluffychat/widgets/twake_components/twake_header_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class TwakeHeader extends StatelessWidget implements PreferredSizeWidget {
  final ChatListController controller;

  const TwakeHeader({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: TwakeHeaderStyle.toolbarHeight,
      automaticallyImplyLeading: false,
      leadingWidth: TwakeHeaderStyle.leadingWidth,
      leading: SizedBox(
        width: 0,
        child: ClientChooserButton(controller),
      ),
      title: SvgPicture.asset(
        Theme.of(context).brightness == Brightness.light
            ? CustomSVGIcons.titleChatListLight
            : CustomSVGIcons.titleChatListDark,
        height: TwakeHeaderStyle.titleHeight,
      ),
      centerTitle: true,
      actions: const [
        Padding(
          padding: EdgeInsets.only(left: 16.0, right: 16.0),
          child: Icon(
            Icons.more_vert,
            size: TwakeHeaderStyle.moreIconSize,
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
