import 'package:dartz/dartz.dart' as dartz;
import 'package:fluffychat/pages/contacts/presentation/contacts_picker.dart';
import 'package:fluffychat/pages/contacts/presentation/extension/list_contact_extension.dart';
import 'package:fluffychat/pages/contacts/presentation/model/presentation_contact.dart';
import 'package:fluffychat/pages/contacts/domain/state/get_contacts_success.dart';
import 'package:fluffychat/pages/contacts/presentation/model/presentation_contacts_info.dart';
import 'package:fluffychat/state/failure.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/avatar/round_avatar.dart';

class ExpansionPanelContactList extends StatefulWidget {

  final ContactsPickerController contactsPickerController;

  final PresentationContactsInfo presentationContacts;

  const ExpansionPanelContactList({
    Key? key,
    required this.contactsPickerController,
    required this.presentationContacts,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ExpansionPanelContactListState();
}

class _ExpansionPanelContactListState extends State<ExpansionPanelContactList> {
  String? searchKey;
  late final Set<PresentationContact> selectedContacts;

  @override
  void initState() {
    selectedContacts = widget.contactsPickerController.selectedContacts;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final presentationContacts = widget.presentationContacts;
    return StreamBuilder(
      stream: presentationContacts.contactsStream,
      builder: (context, AsyncSnapshot<dartz.Either<Failure, GetContactsSuccess>> snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError || snapshot.data?.isLeft() != false) {
          return Text('No contact found.');
        }

        final contactsList = snapshot.data!.fold(
          (failure) => <PresentationContact>[],
          (success) => success.contacts.toPresentationContacts(),
        ).toSet();

        widget.contactsPickerController.setCacheContacts(contactsList, presentationContacts.contactType);
        
        return ExpansionTile(
          initiallyExpanded: presentationContacts.expanded,
          title: Text(presentationContacts.title, style: TextStyle(fontWeight: FontWeight.bold)),
          children: contactsList
            .map<Widget>((contact) => _buildListTile(contact))
            .toList(),
        );
      },
    );
  }

  Widget _buildListTile(PresentationContact contact) {
    return CheckboxListTile(
      value: selectedContacts.contains(contact),
      title: Row(
        children: [
          RoundAvatar(
            text: contact.displayName,
          ),
          const SizedBox(width: 5.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(contact.displayName),
              Text(contact.email, style: TextStyle(fontSize: 14),),
            ],
          ),
        ],
      ),
      selected: selectedContacts.contains(contact), 
      onChanged: (bool? value) {
        if (value != null) {
          setState(() {
            if (value) {
              selectedContacts.add(contact);
            } else {
              selectedContacts.remove(contact);
            }
          });
        }
      },
    );
  }
}