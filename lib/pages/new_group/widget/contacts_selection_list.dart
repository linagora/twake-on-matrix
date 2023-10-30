import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/pages/new_group/widget/contacts_selection_list_style.dart';
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
        (failure) => SliverToBoxAdapter(
          child: Padding(
            padding: ContactsSelectionListStyle.notFoundPadding,
            child: NoContactsFound(
              keyword: failure is GetContactsFailure ? failure.keyword : '',
            ),
          ),
        ),
        (success) {
          if (success is PresentationExternalContactSuccess) {
            return SliverToBoxAdapter(
              child: _ContactItem(
                selectedContactsMapNotifier: selectedContactsMapNotifier,
                onSelectedContact: onSelectedContact,
                contact: success.contact,
                paddingTop: ContactsSelectionListStyle.listPaddingTop,
              ),
            );
          }
          if (success is! PresentationContactsSuccess) {
            return const SliverToBoxAdapter(child: LoadingContactWidget());
          }

          if (success.keyword.isNotEmpty && success.data.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: ContactsSelectionListStyle.notFoundPadding,
                child: NoContactsFound(
                  keyword: success.keyword,
                ),
              ),
            );
          }

          return SliverList.builder(
            itemCount: success.data.length,
            itemBuilder: (context, index) {
              final contact = success.data[index];
              final disabled = disabledContactIds.contains(
                contact.matrixId,
              );
              return _ContactItem(
                contact: contact,
                selectedContactsMapNotifier: selectedContactsMapNotifier,
                onSelectedContact: onSelectedContact,
                highlightKeyword: success.keyword,
                disabled: disabled,
                paddingTop:
                    index == 0 ? ContactsSelectionListStyle.listPaddingTop : 0,
              );
            },
          );
        },
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final PresentationContact contact;
  final SelectedContactsMapChangeNotifier selectedContactsMapNotifier;
  final VoidCallback? onSelectedContact;
  final bool disabled;
  final double paddingTop;
  final String highlightKeyword;

  const _ContactItem({
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
    return InkWell(
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
    );
  }
}
