import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/contacts_tab/empty_contacts_body.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/pages/new_private_chat/widget/loading_contact_widget.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:fluffychat/presentation/model/presentation_contact_success.dart';
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
      controller: controller.scrollController,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: controller.contactsNotifier == null
            ? null
            : ValueListenableBuilder(
                valueListenable: controller.contactsNotifier!,
                builder: (context, value, child) => value.fold(
                  (failure) => const EmptyContactBody(),
                  (success) {
                    if (success is! PresentationContactsSuccess) {
                      return const LoadingContactWidget();
                    }

                    if (success.data.isEmpty) {
                      if (success.keyword.isEmpty) {
                        return const EmptyContactBody();
                      } else {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                          child: NoContactsFound(
                            keyword: success.keyword,
                          ),
                        );
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: success.data
                            .map<Widget>(
                              (contact) => InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  controller.onContactTap(
                                    context: context,
                                    path: 'rooms',
                                    contact: contact,
                                  );
                                },
                                child: ExpansionContactListTile(
                                  contact: contact,
                                  highlightKeyword: success.keyword,
                                ),
                              ),
                            )
                            .toList()
                          ..addAll([
                            ValueListenableBuilder(
                              valueListenable: controller.isSearchModeNotifier,
                              builder: (context, isSearchMode, child) {
                                if (isSearchMode || success.isEnd) {
                                  return const SizedBox.shrink();
                                }
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                            ),
                          ]),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
