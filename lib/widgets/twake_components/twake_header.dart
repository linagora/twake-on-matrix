import 'package:flutter/material.dart';


import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/client_chooser_button.dart';
import 'package:flutter_svg/svg.dart';

class TwakeHeader extends StatelessWidget implements PreferredSizeWidget {
  final ChatListController controller;

  const TwakeHeader({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 52.0,
      automaticallyImplyLeading: false,
      leadingWidth: 70,
      leading: SizedBox(
        width: 0,
        child: ClientChooserButton(controller),
      ),
      title: Image.asset(
        'assets/twake.png',
      ),
      centerTitle: true,
      actions: [
        SvgPicture.asset(
          'assets/human.svg',
          color: Theme.of(context).colorScheme.primary,
          width: 28,
          height: 28,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 12.0),
          child: SvgPicture.asset(
            'assets/edit.svg',
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
