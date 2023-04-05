import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/chat_list/select_chat_list_fab/select_chat_list_fab_style.dart';
import 'package:fluffychat/utils/custom_svg_icons.dart';
import 'package:fluffychat/widgets/twake_components/twake_fab/twake_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

import '../chat_list.dart';

class SelectChatListFloatingActionButton extends StatefulWidget {
  final ChatListController controller;

  const SelectChatListFloatingActionButton({Key? key, required this.controller}) : super(key: key);

  @override
  State<SelectChatListFloatingActionButton> createState() =>
      _SelectChatListFloatingActionButtonState();
}

class _SelectChatListFloatingActionButtonState extends State<SelectChatListFloatingActionButton> {
  void _onPressedGroup(BuildContext context) {
    //
  }

  void _onPressedMessages(BuildContext context) {
    //
  }

  void _onPressedProfile(BuildContext context) {
    //
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: FluffyThemes.animationDuration,
      curve: FluffyThemes.animationCurve,
      width: widget.controller.filteredRooms.isEmpty ? null : SelectChatListFabStyle.buttonWidth,
      child: Container(
        alignment: Alignment.center,
        height: SelectChatListFabStyle.buttonHeight,
        decoration: BoxDecoration(
          boxShadow: SelectChatListFabStyle.boxShadow(context),
          color: SelectChatListFabStyle.backgroundColor(context),
          borderRadius: SelectChatListFabStyle.borderRadius,
        ),
        child: Padding(
          padding: SelectChatListFabStyle.innerPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TwakeFloatingButton(
                buttonText: L10n.of(context)!.groups,
                svgString: CustomSVGIcons.groupsIcon,
                svgHeight: SelectChatListFabStyle.fabButtonSize,
                svgWidth: SelectChatListFabStyle.fabButtonSize,
                notificationCount: 12,
                onTap: () => _onPressedGroup(context),
              ),
              TwakeFloatingButton(
                buttonText: L10n.of(context)!.messages,
                svgString: CustomSVGIcons.messagesIcon,
                svgHeight: SelectChatListFabStyle.fabButtonSize,
                svgWidth: SelectChatListFabStyle.fabButtonSize,
                isSelected: true,
                onTap: () => _onPressedMessages(context),
              ),
              TwakeFloatingButton(
                buttonText: L10n.of(context)!.profile,
                svgString: CustomSVGIcons.rectangleInfoIcon,
                svgHeight: SelectChatListFabStyle.fabButtonSize,
                svgWidth: SelectChatListFabStyle.fabButtonSize,
                onTap: () => _onPressedProfile(context),
              )
            ],
          ),
        ),
      ),
    );
  }
}
