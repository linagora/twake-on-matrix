import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_view_style.dart';
import 'package:fluffychat/pages/contacts_tab/empty_contacts_body.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:flutter/material.dart';

class SliverEmptyContacts extends StatelessWidget {
  const SliverEmptyContacts({required this.controller, super.key});

  final ContactsTabController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        controller.presentationContactNotifier,
        controller.presentationPhonebookContactNotifier,
        controller.presentationRecentContactNotifier,
      ]),
      builder: (context, _) {
        if (controller.isWaitingContacts || controller.hasVisibleContacts) {
          return const SliverToBoxAdapter();
        }
        final keyword = controller.textEditingController.text;
        if (keyword.isEmpty) {
          return SliverToBoxAdapter(
            child: EmptyContactBody(
              onRetrySyncContacts: controller.retrySynchronizeContacts,
            ),
          );
        }
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(
              left: ContactsTabViewStyle.padding,
              top: ContactsTabViewStyle.padding,
            ),
            child: NoContactsFound(keyword: keyword),
          ),
        );
      },
    );
  }
}
