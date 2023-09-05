import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:flutter/material.dart';

import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/pages/new_group/selected_contacts_map_change_notifier.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/pages/new_private_chat/widget/loading_contact_widget.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:fluffychat/presentation/model/presentation_contact_success.dart';

class ContactsSelectionList extends StatelessWidget {
  final SelectedContactsMapChangeNotifier selectedContactsMapNotifier;
  final ValueNotifier<Either<Failure, Success>> contactsNotifier;
  final Function() onSelectedContact;
  final List<String> disabledContactIds;

  const ContactsSelectionList({
    Key? key,
    required this.contactsNotifier,
    required this.selectedContactsMapNotifier,
    required this.onSelectedContact,
    this.disabledContactIds = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: contactsNotifier,
      builder: (context, value, child) => value.fold(
        (failure) => Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: NoContactsFound(
            keyword: failure is GetContactsFailure ? failure.keyword : '',
          ),
        ),
        (success) {
          if (success is PresentationExternalContactSuccess) {
            return _buildContactItem(
              context,
              contact: success.contact,
              paddingTop: 8,
            );
          }
          if (success is! PresentationContactsSuccess) {
            return const LoadingContactWidget();
          }

          if (success.keyword.isNotEmpty && success.data.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: NoContactsFound(
                keyword: success.keyword,
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: success.data.length,
            itemBuilder: (context, index) => _buildContactItem(
              context,
              contact: success.data[index],
              paddingTop: index == 0 ? 8.0 : 0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context, {
    required PresentationContact contact,
    double paddingTop = 0,
  }) {
    final contactNotifier =
        selectedContactsMapNotifier.getNotifierAtContact(contact);
    final disabled = disabledContactIds.contains(
      contact.matrixId,
    );
    return InkWell(
      key: ValueKey(contact.matrixId),
      onTap: disabled
          ? null
          : () {
              selectedContactsMapNotifier.onContactTileTap(
                context,
                contact,
              );
            },
      borderRadius: BorderRadius.circular(16.0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: EdgeInsets.only(
            left: 8.0,
            right: 16,
            top: paddingTop,
          ),
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
                            selectedContactsMapNotifier.onContactTileTap(
                              context,
                              contact,
                            );
                            onSelectedContact();
                          },
                  );
                },
              ),
              Expanded(
                child: ExpansionContactListTile(
                  contact: contact,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
