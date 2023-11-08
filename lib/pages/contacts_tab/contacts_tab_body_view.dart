import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_view_style.dart';
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
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Divider(
            height: 1,
            thickness: 1,
            color: Colors.black.withOpacity(0.15),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(
            height: ContactsTabViewStyle.padding,
          ),
        ),
        ValueListenableBuilder(
          valueListenable: controller.presentationContactNotifier,
          builder: (context, presentationContact, child) {
            if (controller.contactManager.firstSynchronizing &&
                presentationContact.isEmpty) {
              return const SliverToBoxAdapter(
                child: LoadingContactWidget(),
              );
            }

            if (presentationContact.isEmpty) {
              if (controller.textEditingController.text.isEmpty) {
                return const SliverToBoxAdapter(child: EmptyContactBody());
              } else {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: ContactsTabViewStyle.padding,
                      top: ContactsTabViewStyle.padding,
                    ),
                    child: NoContactsFound(
                      keyword: controller.textEditingController.text,
                    ),
                  ),
                );
              }
            }

            return SliverList.builder(
              itemCount: presentationContact.length,
              itemBuilder: (context, index) {
                final contact = presentationContact[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ContactsTabViewStyle.padding,
                  ),
                  child: InkWell(
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
                      highlightKeyword: controller.textEditingController.text,
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SliverToBoxAdapter(
          child: SizedBox(
            height: ContactsTabViewStyle.padding,
          ),
        ),
      ],
    );
  }
}
