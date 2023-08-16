import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:flutter/material.dart';

import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/pages/new_group/selected_contacts_map_change_notiifer.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/pages/new_private_chat/widget/loading_contact_widget.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:fluffychat/presentation/model/presentation_contact_success.dart';

class ContactsSelectionList extends StatelessWidget {
  final SelectedContactsMapChangeNotifier selectedContactsMapNotifier;
  final ValueNotifier<Either<Failure, Success>> contactsNotifier;
  final Function() onSelectedContact;
  final ValueNotifier<bool> isSearchModeNotifier;

  const ContactsSelectionList({
    Key? key,
    required this.contactsNotifier,
    required this.selectedContactsMapNotifier,
    required this.isSearchModeNotifier,
    required this.onSelectedContact,
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

          return Column(
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: success.data.length,
                itemBuilder: (context, index) {
                  final contactNotifier = selectedContactsMapNotifier
                      .getNotifierAtContact(success.data[index]);
                  return InkWell(
                    key: ValueKey(success.data[index].matrixId),
                    onTap: () {
                      selectedContactsMapNotifier.onContactTileTap(
                        context,
                        success.data[index],
                      );
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
                                contact: success.data[index],
                              ),
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: contactNotifier,
                              builder: (context, isCurrentSelected, child) {
                                return Checkbox(
                                  value: contactNotifier.value,
                                  onChanged: (newValue) {
                                    selectedContactsMapNotifier
                                        .onContactTileTap(
                                      context,
                                      success.data[index],
                                    );
                                    onSelectedContact();
                                  },
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              ValueListenableBuilder<bool>(
                valueListenable: isSearchModeNotifier,
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
              )
            ],
          );
        },
      ),
    );
  }
}
