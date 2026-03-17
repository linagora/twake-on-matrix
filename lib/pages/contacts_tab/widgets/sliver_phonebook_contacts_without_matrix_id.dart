import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_view_style.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_phonebook_contact_list_tile.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact_success.dart';
import 'package:fluffychat/widgets/sliver_expandable_list.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

class SliverPhonebookContactsWithoutMatrixId extends StatelessWidget {
  const SliverPhonebookContactsWithoutMatrixId({
    required this.controller,
    super.key,
  });

  final ContactsTabController controller;

  @override
  Widget build(BuildContext context) {
    const empty = SliverToBoxAdapter();
    return ValueListenableBuilder(
      valueListenable: controller.presentationPhonebookContactNotifier,
      builder: (context, state, _) {
        return state.fold((_) => empty, (success) {
          if (success is PresentationContactsSuccess) {
            final contacts = success.contacts
                .where((c) => c.matrixId == null || c.matrixId!.isEmpty)
                .toList();
            if (contacts.isEmpty) {
              return empty;
            }
            return SliverExpandableList(
              title: L10n.of(context)!.contactsCount(contacts.length),
              itemCount: contacts.length,
              itemBuilder: (context, index) => _PhonebookContactTile(
                contact: contacts[index],
                controller: controller,
              ),
            );
          }
          return empty;
        });
      },
    );
  }
}

class _PhonebookContactTile extends StatelessWidget {
  const _PhonebookContactTile({
    required this.contact,
    required this.controller,
  });

  final PresentationContact contact;
  final ContactsTabController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ContactsTabViewStyle.padding,
      ),
      child: ExpansionPhonebookContactListTile(
        contact: contact,
        highlightKeyword: controller.textEditingController.text,
        enableInvitation: controller.supportInvitation(),
        onContactTap: () => controller.onContactTap(
          context: context,
          path: 'rooms',
          contact: contact,
        ),
      ),
    );
  }
}
