import 'package:fluffychat/utils/dialog/warning_dialog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

mixin InviteExternalContactMixin {
  void showInviteExternalContactDialog(
    BuildContext context,
    VoidCallback onAccept,
  ) {
    WarningDialog.showCancelable(
      context,
      title: L10n.of(context)?.externalContactTitle,
      message: L10n.of(context)?.externalContactMessage,
      acceptText: L10n.of(context)?.invite,
      cancelText: L10n.of(context)?.skip,
      onAccept: onAccept,
    );
  }
}
