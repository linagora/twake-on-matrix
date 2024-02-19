import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/mixins/popup_menu_widget_style.dart';
import 'package:flutter/material.dart';

mixin PopupContextMenuActionMixin {
  void openPopupMenuAction(
    BuildContext context,
    RelativeRect? position,
    List<PopupMenuEntry> popupMenuItems, {
    VoidCallback? onClose,
  }) async {
    await showMenu(
      constraints: const BoxConstraints(
        minWidth: PopupMenuWidgetStyle.menuMaxWidth,
        maxWidth: PopupMenuWidgetStyle.menuMaxWidth,
      ),
      surfaceTintColor: PopupMenuWidgetStyle.defaultMenuColor(context),
      context: context,
      position: position ?? const RelativeRect.fromLTRB(16, 40, 16, 16),
      elevation: PopupMenuWidgetStyle.menuElevation,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(PopupMenuWidgetStyle.menuBorderRadius),
      ),
      items: popupMenuItems,
      useRootNavigator: PlatformInfos.isWeb,
    ).then((value) {
      onClose?.call();
    });
  }
}
