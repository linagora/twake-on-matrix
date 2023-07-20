import 'package:fluffychat/utils/warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

typedef OnAcceptButton = void Function()?;

class WarningDialog {
  static void showWarningDialog(BuildContext context,
      {OnAcceptButton? onAcceptButton}) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (c) => WarningDialogWidget(
        explainTextRequestWidget: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: L10n.of(context)!
                .youAreUploadingPhotosDoYouWantToCancelOrContinue,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        onAcceptButton: () {
          onAcceptButton?.call();
        },
      ),
    );
  }

  static void hideWarningDialog(BuildContext context) {
    Navigator.pop(context);
  }
}
