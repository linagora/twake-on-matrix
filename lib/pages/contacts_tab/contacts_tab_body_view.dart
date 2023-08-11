import 'package:collection/collection.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/contacts_tab/empty_contacts_body.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/pages/new_private_chat/widget/loading_contact_widget.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:flutter/material.dart';

class ContactsTabBodyView extends StatelessWidget {
  final ContactsTabController controller;

  const ContactsTabBodyView(
    this.controller, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller.fetchContactsController.scrollController,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: StreamBuilder(
          stream: controller.contactsStreamController.stream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const LoadingContactWidget();
            }

            if (snapshot.hasError || snapshot.data!.isLeft()) {
              return const EmptyContactBody();
            }

            final contactsList = controller.fetchContactsController
                .getContactsFromFetchStream(snapshot.data!);

            final contactsListSorted = contactsList
                .sorted((a, b) => controller.comparePresentationContacts(a, b));

            if (contactsListSorted.isEmpty) {
              if (controller.searchContactsController.searchKeyword.isEmpty) {
                return const EmptyContactBody();
              } else {
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                  child: NoContactsFound(
                    keyword: controller.searchContactsController.searchKeyword,
                  ),
                );
              }
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: contactsListSorted
                    .map<Widget>(
                      (contact) => InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          controller.onContactTap(
                            context: context,
                            path: 'contacts',
                            contact: contact,
                          );
                        },
                        child: ExpansionContactListTile(contact: contact),
                      ),
                    )
                    .toList()
                  ..addAll([
                    ValueListenableBuilder(
                      valueListenable: controller
                          .searchContactsController.isSearchModeNotifier,
                      builder: (context, isSearchMode, child) {
                        if (isSearchMode) {
                          return const SizedBox.shrink();
                        }
                        return ValueListenableBuilder(
                          valueListenable: controller.fetchContactsController
                              .haveMoreCountactsNotifier,
                          builder: (context, haveMoreContacts, child) {
                            if (haveMoreContacts) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            return const SizedBox.shrink();
                          },
                        );
                      },
                    ),
                  ]),
              ),
            );
          },
        ),
      ),
    );
  }
}
