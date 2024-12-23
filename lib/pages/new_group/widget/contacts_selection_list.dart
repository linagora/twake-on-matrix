import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/pages/new_group/widget/contact_item.dart';
import 'package:fluffychat/pages/new_group/widget/contacts_selection_list_style.dart';
import 'package:fluffychat/pages/new_private_chat/widget/loading_contact_widget.dart';
import 'package:fluffychat/presentation/model/contact/get_presentation_contacts_empty.dart';
import 'package:fluffychat/presentation/model/contact/get_presentation_contacts_failure.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact_success.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/widgets/sliver_expandable_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/pages/new_group/selected_contacts_map_change_notifier.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';

class ContactsSelectionList extends StatelessWidget {
  final SelectedContactsMapChangeNotifier selectedContactsMapNotifier;
  final ValueNotifier<List<PresentationSearch>>
      presentationRecentContactNotifier;
  final ValueNotifier<Either<Failure, Success>> presentationContactNotifier;
  final Function() onSelectedContact;
  final List<String> disabledContactIds;
  final TextEditingController textEditingController;

  const ContactsSelectionList({
    super.key,
    required this.presentationContactNotifier,
    required this.selectedContactsMapNotifier,
    required this.onSelectedContact,
    this.disabledContactIds = const [],
    required this.textEditingController,
    required this.presentationRecentContactNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: presentationContactNotifier,
      builder: (context, state, child) {
        final isSearchModeEnable = textEditingController.text.isNotEmpty;
        final recentContact = presentationRecentContactNotifier.value.isEmpty;
        return state.fold(
          (failure) {
            final textControllerIsEmpty = textEditingController.text.isEmpty;
            if (failure is GetPresentationContactsEmpty ||
                failure is GetPresentationContactsFailure) {
              if (recentContact) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: ContactsSelectionListStyle.notFoundPadding,
                    child: NoContactsFound(
                      keyword: textControllerIsEmpty
                          ? null
                          : textEditingController.text,
                    ),
                  ),
                );
              }
            }
            return child!;
          },
          (success) {
            if (success is ContactsLoading) {
              return const SliverToBoxAdapter(
                child: LoadingContactWidget(),
              );
            }

            if (success is PresentationExternalContactSuccess &&
                recentContact) {
              return SliverToBoxAdapter(
                child: ContactItem(
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
              return SliverExpandableList(
                title: L10n.of(context)!.linagoraContactsCount(contacts.length),
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final disabled = disabledContactIds.contains(
                    contacts[index].matrixId,
                  );
                  return ContactItem(
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
