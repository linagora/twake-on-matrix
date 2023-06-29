
import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_success.dart';
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
  late final selectedContactsMapNotifier = widget.newGroupController.selectedContactsMapNotifier;
  late final contactsList = widget.newGroupController.selectedContactsMapNotifier.contactsList; 
  late final fetchContactsController = widget.newGroupController.fetchContactsController;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Either<Failure, GetContactsSuccess>>(
      stream: widget.newGroupController.contactStreamController.stream,
      builder: (context, snapshot) {
        final searchKeyword = widget.newGroupController.searchContactsController.searchKeyword;
        final fetchContactsController = widget.newGroupController.fetchContactsController;
        if (!snapshot.hasData) {
          return const LoadingContactWidget();
        }

        final contactsList = fetchContactsController
          .getContactsFromFetchStream(snapshot.data!)
          .toList();

        contactsList.sort((a, b) => widget.newGroupController.comparePresentationContacts(a, b));

        if (searchKeyword.isNotEmpty && contactsList.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: NoContactsFound(keyword: widget.newGroupController.searchContactsController.searchKeyword),
          );
        }
        
        return Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: contactsList.length,
              itemBuilder: (context, i) {
                final contactNotifier = selectedContactsMapNotifier.getNotifierAtContact(contactsList[i]);
                return InkWell(
                  key: ValueKey(contactsList[i].matrixId),
                  onTap: () {
                    selectedContactsMapNotifier.onContactTileTap(contact: contactsList[i]);
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
                          ValueListenableBuilder<bool>(
                            valueListenable: contactNotifier,
                            builder: (context, isCurrentSelected, child) {
                              return Checkbox(
                                value: contactNotifier.value,
                                onChanged: (newValue) {
                                  selectedContactsMapNotifier.onContactTileTap(contact: contactsList[i]);
                                },
                              );
                            }
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }
            ),
            ValueListenableBuilder<bool>(
              valueListenable: widget.newGroupController.searchContactsController.isSearchModeNotifier,
              builder: (context, isSearchMode, child) {
                if (isSearchMode) {
                  return const SizedBox.shrink();
                }
                return ValueListenableBuilder(
                  valueListenable: fetchContactsController.haveMoreCountactsNotifier,
                  builder: (context, value, child) {
                    if (value) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ); 
                    }

                    return const SizedBox.shrink();
                  }
                );
              }
            )
          ],
        );
      },
    );
  }

}