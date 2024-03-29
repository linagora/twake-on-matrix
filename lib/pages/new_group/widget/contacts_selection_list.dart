import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/pages/new_group/widget/contacts_selection_list_style.dart';
import 'package:fluffychat/pages/new_private_chat/widget/loading_contact_widget.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/presentation/model/presentation_contact_success.dart';
import 'package:flutter/material.dart';

import 'package:fluffychat/pages/new_group/selected_contacts_map_change_notifier.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';

class ContactsSelectionList extends StatelessWidget {
  final SelectedContactsMapChangeNotifier selectedContactsMapNotifier;
  final ValueNotifier<Either<Failure, Success>> presentationContactNotifier;
  final Function() onSelectedContact;
  final List<String> disabledContactIds;
  final TextEditingController textEditingController;

  const ContactsSelectionList({
    Key? key,
    required this.presentationContactNotifier,
    required this.selectedContactsMapNotifier,
    required this.onSelectedContact,
    this.disabledContactIds = const [],
    required this.textEditingController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: presentationContactNotifier,
      builder: (context, state, child) {
        final isSearchModeEnable = textEditingController.text.isNotEmpty;

        return state.fold(
          (_) => child!,
          (success) {
            if (success is ContactsLoading) {
              return const SliverToBoxAdapter(
                child: LoadingContactWidget(),
              );
            }

            if (success is PresentationExternalContactSuccess) {
              return SliverToBoxAdapter(
                child: _ContactItem(
                  contact: success.contact,
                  selectedContactsMapNotifier: selectedContactsMapNotifier,
                  onSelectedContact: onSelectedContact,
                  highlightKeyword: textEditingController.text,
                  disabled: false,
                ),
              );
            }

            if (success is PresentationContactsSuccess) {
              final contacts = success.contacts;
              if (contacts.isEmpty && isSearchModeEnable) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: ContactsSelectionListStyle.notFoundPadding,
                    child: NoContactsFound(
                      keyword: textEditingController.text,
                    ),
                  ),
                );
              }
              return SliverList.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final disabled = disabledContactIds.contains(
                    contacts[index].matrixId,
                  );
                  return _ContactItem(
                    contact: contacts[index],
                    selectedContactsMapNotifier: selectedContactsMapNotifier,
                    onSelectedContact: onSelectedContact,
                    highlightKeyword: textEditingController.text,
                    disabled: disabled,
                    paddingTop: index == 0
                        ? ContactsSelectionListStyle.listPaddingTop
                        : 0,
                  );
                },
              );
            }
            return child!;
          },
        );
      },
      child: const SliverToBoxAdapter(child: SizedBox()),
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
