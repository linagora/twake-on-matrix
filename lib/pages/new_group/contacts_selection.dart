import 'package:fluffychat/domain/model/contact/contact_type.dart';
import 'package:fluffychat/mixin/invite_external_contact_mixin.dart';
import 'package:fluffychat/pages/new_group/contacts_selection_view.dart';
import 'package:fluffychat/pages/new_group/selected_contacts_map_change_notifier.dart';
import 'package:fluffychat/presentation/mixins/contact_manager_mixin.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:flutter/cupertino.dart';

abstract class ContactsSelectionController<T extends StatefulWidget>
    extends State<T> with ContactManagerMixin, InviteExternalContactMixin {
  final selectedContactsMapNotifier = SelectedContactsMapChangeNotifier();

  String getTitle(BuildContext context);

  String getHintText(BuildContext context);

  void onSubmit();

  List<String> get disabledContactIds => [];

  Iterable<PresentationContact> get contactsList =>
      selectedContactsMapNotifier.contactsList;

  bool get isContainsExternal =>
      contactsList.any((contact) => contact.type == ContactType.external);

  bool get isFullScreen => true;

  @override
  void initState() {
    initSearchExternalContacts();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void trySubmit(BuildContext context) {
    if (isContainsExternal) {
      showInviteExternalContactDialog(context, onSubmit);
    } else {
      onSubmit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContactsSelectionView(this);
  }
}
