import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/add_contact/add_contact_dialog_view.dart';
import 'package:fluffychat/presentation/extensions/contact/presentation_contact_extension.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

Future<void> showAddContactDialog(
  BuildContext context, {
  String? displayName,
  String? matrixId,
}) async {
  return showModalBottomSheet(
    context: context,
    backgroundColor: LinagoraSysColors.material().onPrimary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    useSafeArea: true,
    scrollControlDisabledMaxHeightRatio: 0.8,
    builder: (context) {
      return AddContactDialog(
        displayName: displayName,
        matrixId: matrixId,
      );
    },
  );
}

class AddContactDialog extends StatefulWidget {
  const AddContactDialog({super.key, this.displayName, this.matrixId});

  final String? displayName;
  final String? matrixId;

  @override
  State<AddContactDialog> createState() => AddContactDialogController();
}

class AddContactDialogController extends State<AddContactDialog> {
  String firstName = '';
  String lastName = '';
  late final ValueNotifier<String> userName;

  List<PresentationContact> get availableContacts =>
      getIt
          .get<ContactsManager>()
          .getContactsNotifier()
          .value
          .getSuccessOrNull<GetContactsSuccess>()
          ?.contacts
          .expand((contact) => contact.toPresentationContacts())
          .toList() ??
      [];

  @override
  void initState() {
    super.initState();
    firstName = widget.displayName ?? '';

    userName = ValueNotifier(widget.matrixId ?? '');
  }

  @override
  void dispose() {
    userName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AddContactDialogView(controller: this);
  }
}
