import 'package:fluffychat/pages/new_private_chat/search_contacts_controller.dart';
import 'package:fluffychat/presentation/converters/presentation_contact_converter.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/utils/dialog/warning_dialog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

mixin InviteExternalContactMixin on SearchContactsController {
  void initSearchExternalContacts() {
    initSearchContacts(
      converter: PresentationContactConverter(checkExternal: true),
    );
  }

  void showInviteExternalContactDialog(
    BuildContext context,
    PresentationContact contact,
    Function() onAccept,
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
