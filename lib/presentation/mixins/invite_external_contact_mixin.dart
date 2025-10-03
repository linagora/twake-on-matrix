import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:flutter/widgets.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

mixin InviteExternalContactMixin {
  void showInviteExternalContactDialog(
    BuildContext context,
    VoidCallback onAccept,
  ) async {
    await showConfirmAlertDialog(
      context: context,
      title: L10n.of(context)?.externalContactTitle,
      message: L10n.of(context)?.externalContactMessage,
      okLabel: L10n.of(context)?.invite,
      cancelLabel: L10n.of(context)?.skip,
    ).then((result) {
      if (result == ConfirmResult.ok) {
        onAccept();
      }
    });
  }
}
