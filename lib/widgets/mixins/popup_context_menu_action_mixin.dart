import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

mixin PopupContextMenuActionMixin {
  void openPopupMenuAction(
    BuildContext context,
    RelativeRect? position,
    List<PopupMenuEntry> popupMenuItems, {
    VoidCallback? onClose,
  }) async {
    await showMenu(
      context: context,
      position: position ?? const RelativeRect.fromLTRB(16, 40, 16, 16),
      color: LinagoraSysColors.material().surface,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      items: popupMenuItems,
      useRootNavigator: PlatformInfos.isWeb,
    ).then((value) {
      onClose?.call();
    });
  }
}
