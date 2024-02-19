import 'package:fluffychat/presentation/enum/chat/popup_menu_item_web_enum.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/presentation/extensions/text_editting_controller_extension.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

class ContextMenuInputBar extends StatelessWidget {
  final Widget child;

  final TextEditingController? controller;

  final VoidCallback? handlePaste;

  final Room? room;

  final FocusNode? focusNode;

  const ContextMenuInputBar({
    super.key,
    required this.child,
    required this.handlePaste,
    this.controller,
    this.room,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (PointerDownEvent event) async {
        if (event.kind == PointerDeviceKind.mouse &&
            event.buttons == kSecondaryMouseButton) {
          // FIXME: the contextMenuBuilder.editable can do this but its style in web is not customizable
          // currently this is only solution
          final screenSize = MediaQuery.sizeOf(context);
          final offset = event.position;
          final position = RelativeRect.fromLTRB(
            offset.dx,
            offset.dy,
            screenSize.width - offset.dx,
            screenSize.height - offset.dy,
          );
          final menuItem = await showMenu<InputBarContextMenu>(
            useRootNavigator: PlatformInfos.isWeb,
            context: context,
            items: [
              PopupMenuItem(
                value: InputBarContextMenu.copy,
                child: Text(L10n.of(context)!.copy),
              ),
              PopupMenuItem(
                value: InputBarContextMenu.cut,
                child: Text(L10n.of(context)!.cut),
              ),
              PopupMenuItem(
                value: InputBarContextMenu.paste,
                child: Text(L10n.of(context)!.paste),
              ),
            ],
            position: position,
          );

          if (menuItem == null || controller == null) {
            return;
          }

          switch (menuItem) {
            case InputBarContextMenu.copy:
              controller!.copyText();
              break;
            case InputBarContextMenu.cut:
              controller!.cutText();
              break;
            case InputBarContextMenu.paste:
              handlePaste?.call();
              break;
          }
          FocusScope.of(context).requestFocus(focusNode);
        }
      },
      child: child,
    );
  }
}
