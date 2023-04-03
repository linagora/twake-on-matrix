import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/utils/custom_svg_icons.dart';
import 'package:fluffychat/widgets/twake_components/twake_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'chat_list.dart';

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
      width: widget.controller.filteredRooms.isEmpty ? null : 263,
      child: Container(
        alignment: Alignment.center,
        height: 66,
        decoration: BoxDecoration(
          boxShadow: Theme.of(context).brightness == Brightness.light ? const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.12),
              offset: Offset(0, 0),
              blurRadius: 2,
            ),
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.16),
              offset: Offset(0, 0),
              blurRadius: 96,
            ),
          ] : [],
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : const Color.fromARGB(239, 36, 36, 36),
          borderRadius: const BorderRadius.all(Radius.circular(32)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TwakeFloatingButton(
                buttonText: L10n.of(context)!.groups,
                svgString: CustomSVGIcons.groupsIcon,
                svgHeight: 28,
                svgWidth: 28,
                notificationCount: 12,
                onTap: () => _onPressedGroup(context),
              ),
              TwakeFloatingButton(
                buttonText: L10n.of(context)!.messages,
                svgString: CustomSVGIcons.messagesIcon,
                svgHeight: 28,
                svgWidth: 28,
                isSelected: true,
                onTap: () => _onPressedMessages(context),
              ),
              TwakeFloatingButton(
                buttonText: L10n.of(context)!.profile,
                svgString: CustomSVGIcons.rectangleInfoIcon,
                svgHeight: 28,
                svgWidth: 28,
                onTap: () => _onPressedProfile(context),
              )
            ],
          ),
        ),
      ),
    );
  }
}
