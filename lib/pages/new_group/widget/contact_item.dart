import 'package:fluffychat/pages/new_group/selected_contacts_map_change_notifier.dart';
import 'package:fluffychat/pages/new_group/widget/contacts_selection_list_style.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:flutter/material.dart';

class ContactItem extends StatelessWidget {
  final PresentationContact contact;
  final SelectedContactsMapChangeNotifier selectedContactsMapNotifier;
  final VoidCallback? onSelectedContact;
  final bool disabled;
  final double paddingTop;
  final String highlightKeyword;

  const ContactItem({
    super.key,
    required this.contact,
    required this.selectedContactsMapNotifier,
    this.onSelectedContact,
    this.highlightKeyword = '',
    this.disabled = false,
    this.paddingTop = 0,
  });

  @override
  Widget build(BuildContext context) {
    final contactNotifier =
        selectedContactsMapNotifier.getNotifierAtContact(contact);
    return Padding(
      padding: ContactsSelectionListStyle.contactItemPadding,
      child: InkWell(
        key: ValueKey(contact.matrixId),
        onTap: disabled
            ? null
            : () {
                onSelectedContact?.call();
                selectedContactsMapNotifier.onContactTileTap(
                  context,
                  contact,
                );
              },
        borderRadius: ContactsSelectionListStyle.contactItemBorderRadius,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: ContactsSelectionListStyle.checkBoxPadding(paddingTop),
            child: Row(
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: contactNotifier,
                  builder: (context, isCurrentSelected, child) {
                    return Checkbox(
                      value: disabled || contactNotifier.value,
                      onChanged: disabled
                          ? null
                          : (newValue) {
                              onSelectedContact?.call();
                              selectedContactsMapNotifier.onContactTileTap(
                                context,
                                contact,
                              );
                            },
                    );
                  },
                ),
                Expanded(
                  child: ExpansionContactListTile(
                    contact: contact,
                    highlightKeyword: highlightKeyword,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
