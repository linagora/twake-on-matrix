import 'package:fluffychat/pages/new_group/contacts_selection.dart';
import 'package:fluffychat/pages/new_group/contacts_selection_view_style.dart';
import 'package:fluffychat/pages/new_group/widget/contacts_selection_list.dart';
import 'package:fluffychat/pages/new_group/widget/selected_participants_list.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_fab.dart';
import 'package:fluffychat/widgets/twake_components/twake_smart_refresher.dart';
import 'package:flutter/material.dart';

class ContactsSelectionView extends StatelessWidget {
  final ContactsSelectionController controller;

  const ContactsSelectionView(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: SearchableAppBarStyle.preferredSize(context),
        child: SearchableAppBar(
          focusNode: controller.searchFocusNode,
          title: controller.getTitle(context),
          searchModeNotifier: controller.isSearchModeNotifier,
          hintText: controller.getHintText(context),
          textEditingController: controller.textEditingController,
          toggleSearchMode: controller.toggleSearchMode,
        ),
      ),
      body: Column(
        children: [
          SelectedParticipantsList(
            contactsSelectionController: controller,
          ),
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: controller
                  .selectedContactsMapNotifier.haveSelectedContactsNotifier,
              builder: (context, haveSelectedContact, child) {
                return Padding(
                  padding: ContactsSelectionViewStyle.getSelectionListPadding(
                    haveSelectedContact: haveSelectedContact,
                  ),
                  child: child,
                );
              },
              child: controller.contactsNotifier == null ||
                      controller.refreshController == null
                  ? null
                  : TwakeSmartRefresher(
                      controller: controller.refreshController!,
                      onRefresh: controller.fetchContacts,
                      onLoading: controller.loadMoreContacts,
                      child: ContactsSelectionList(
                        contactsNotifier: controller.contactsNotifier!,
                        selectedContactsMapNotifier:
                            controller.selectedContactsMapNotifier,
                        onSelectedContact: controller.onSelectedContact,
                        disabledContactIds: controller.disabledContactIds,
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable:
            controller.selectedContactsMapNotifier.haveSelectedContactsNotifier,
        builder: (context, haveSelectedContacts, child) {
          if (!haveSelectedContacts) {
            return const SizedBox.shrink();
          }
          return child!;
        },
        child: TwakeFloatingActionButton(
          icon: Icons.arrow_forward,
          onTap: () => controller.trySubmit(context),
        ),
      ),
    );
  }
}
