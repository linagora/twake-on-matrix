import 'package:fluffychat/pages/contacts/presentation/contacts_picker.dart';
import 'package:fluffychat/pages/contacts/presentation/model/presentation_contacts_info.dart';
import 'package:fluffychat/pages/contacts/presentation/widget/expansion_panel_contact_list.dart';
import 'package:fluffychat/pages/contacts/presentation/widget/expansion_panel_device_contact_list.dart';
import 'package:fluffychat/pages/contacts/presentation/widget/search_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


class ContactsPickerView extends StatelessWidget {

  final ContactsPickerController contactsPickerController;

  const ContactsPickerView(
    this.contactsPickerController,
    {Key? key}
  ): super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: SingleChildScrollView(
        child: CustomScrollView(
        shrinkWrap: true,
        slivers: [
          SliverAppBar(
            leading: const SizedBox.shrink(),
            leadingWidth: 0,
            centerTitle: true,
            pinned: true,
            title: SearchBar(contactsPickerController: contactsPickerController),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final presentationContacts = contactsPickerController.presentationContactsList[index];
              if (presentationContacts.contactType == ContactType.device) {
                if (kIsWeb) {
                  return const SizedBox.shrink();
                }
                return ExpansionPanelDeviceContactList(
                  child: ExpansionPanelContactList(
                    contactsPickerController: contactsPickerController,
                    presentationContacts: presentationContacts));
              }

              return ExpansionPanelContactList(
                contactsPickerController: contactsPickerController,
                presentationContacts: presentationContacts,);
            },
            childCount: 2,),
          )
        ],
      ),
      ));
  }
}