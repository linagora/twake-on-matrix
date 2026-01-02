import 'package:fluffychat/widgets/context_menu/context_menu_action.dart';
import 'package:flutter/foundation.dart';

class ChatParticipantContextMenuItem extends ContextMenuAction {
  final VoidCallback onTap;

  const ChatParticipantContextMenuItem({
    required super.name,
    super.icon,
    super.imagePath,
    super.colorIcon,
    super.iconSize,
    super.styleName,
    super.padding,
    required this.onTap,
  });
}
