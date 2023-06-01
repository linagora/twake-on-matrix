
import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_success.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/data/model/presentation_contact.dart';
import 'package:fluffychat/mixin/comparable_presentation_contact_mixin.dart';
import 'package:fluffychat/pages/new_group/new_group.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/pages/new_private_chat/widget/loading_contact_widget.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:flutter/material.dart';

class ContactsSelectionList extends StatefulWidget {

  final NewGroupController newGroupController;

  const ContactsSelectionList({
    super.key,
    required this.newGroupController,
  });

  @override
  State<StatefulWidget> createState() => _ContactsSelectionListState();
}

class _ContactsSelectionListState extends State<ContactsSelectionList> {
  late final selectedContactsMap = widget.newGroupController.selectedContactsMapNotifier.value;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Either<Failure, GetContactsSuccess>>(
      stream: widget.newGroupController.contactStreamController.stream,
      builder: (context, snapshot) {
        final searchKeyword = widget.newGroupController.searchContactsController.searchKeyword;
        if (!snapshot.hasData) {
          return const LoadingContactWidget();
        }

        final contactsList = snapshot.data!.fold(
          (failure) => <PresentationContact>[],
          (success) => success.contacts.expand((contact) => contact.toPresentationContacts()),
        ).toList();

        contactsList.sort((a, b) => widget.newGroupController.comparePresentationContacts(a, b));

        if (searchKeyword.isNotEmpty && contactsList.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: NoContactsFound(keyword: widget.newGroupController.searchContactsController.searchKeyword),
          );
        }
        
        return ValueListenableBuilder<Map<PresentationContact, bool>>(
          valueListenable: widget.newGroupController.selectedContactsMapNotifier,
          builder: (context, selectedContactsMap, child) {
            return Column(
              children: List<Widget>.generate(
                contactsList.length,
                (i) {
                  return InkWell(
                    onTap: () {
                      final val = selectedContactsMap[contactsList[i]] ?? false;
                      setState(() {
                        selectedContactsMap[contactsList[i]] = !val;
                      });
                      selectedContactsMap[contactsList[i]]!
                        ? widget.newGroupController.selectContact(contactsList[i])
                        : widget.newGroupController.unselectContact(contactsList[i]);
                    },
                    borderRadius: BorderRadius.circular(16.0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ExpansionContactListTile(
                                contact: contactsList[i]),
                            ),
                            Checkbox(
                              value: selectedContactsMap[contactsList[i]] ?? false,
                              onChanged: (isCurrentSelected) {
                                setState(() {
                                  selectedContactsMap[contactsList[i]] 
                                    = isCurrentSelected ?? false;
                                });
                                isCurrentSelected != null && isCurrentSelected
                                  ? widget.newGroupController.selectContact(contactsList[i])
                                  : widget.newGroupController.unselectContact(contactsList[i]);
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            );
          },
        );
      },
    );
  }

}