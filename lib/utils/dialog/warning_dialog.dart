import 'package:fluffychat/utils/warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

typedef OnAcceptButton = void Function()?;

class WarningDialog {
  static void show(
    BuildContext context, {
    String? title,
    String? message,
    List<DialogAction>? actions,
  }) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (c) => WarningDialogWidget(
        title: title,
        message: message,
        actions: actions,
      ),
    );
  }

  static void showCancelable(
    BuildContext context, {
    String? title,
    String? message,
    String? acceptText,
    Color? acceptTextColor,
    OnAcceptButton? onAccept,
    String? cancelText,
    Color? cancelTextColor,
    OnAcceptButton? onCancel,
  }) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (c) => WarningDialogWidget(
        title: title,
        message: message,
        actions: [
          DialogAction(
            text: cancelText ?? L10n.of(context)!.cancel,
            textColor: cancelTextColor,
            onPressed: () {
              Navigator.pop(context);
              onCancel?.call();
            },
          ),
          DialogAction(
            text: acceptText ?? L10n.of(context)!.ok,
            textColor: acceptTextColor,
            onPressed: () {
              Navigator.pop(context);
              onAccept?.call();
            },
          ),
        ],
      ),
    );
  }

  static void hideWarningDialog(BuildContext context) {
    Navigator.pop(context);
  }
}
