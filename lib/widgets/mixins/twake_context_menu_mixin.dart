import 'package:twake_chat/widgets/context_menu/context_menu_action.dart';
import 'package:twake_chat/widgets/context_menu/twake_context_menu.dart';
import 'package:flutter/material.dart';

/// Show a [TwakeContextMenu] on the given [BuildContext]. For other parameters, see [TwakeContextMenu].
mixin TwakeContextMenuMixin {
  Future<dynamic> showTwakeContextMenu({
    required List<ContextMenuAction> listActions,
    required Offset offset,
    required BuildContext context,
    double? verticalPadding,
    VoidCallback? onClose,
    bool leadingIcon = false,
    bool respectLeftPosition = false,
  }) async {
    dynamic result;
    await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (dialogContext) => TwakeContextMenu(
        dialogContext: dialogContext,
        listActions: listActions,
        position: offset,
        verticalPadding: verticalPadding,
        leadingIcon: leadingIcon,
        respectLeftPosition: respectLeftPosition,
      ),
    ).then((value) {
      result = value;
      onClose?.call();
    });
    return result;
  }
}
