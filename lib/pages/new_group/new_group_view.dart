import 'package:fluffychat/pages/new_group/widget/contacts_selection_list.dart';
import 'package:fluffychat/pages/new_group/widget/selected_participants_list.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_fab.dart';
import 'package:fluffychat/widgets/twake_components/twake_smart_refresher.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/pages/new_group/new_group.dart';

class NewGroupView extends StatelessWidget {
  final NewGroupController controller;

  const NewGroupView(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: SearchableAppBarStyle.preferredSize(context),
        child: SearchableAppBar(
          focusNode: controller.searchFocusNode,
          title: L10n.of(context)!.newGroupChat,
          searchModeNotifier: controller.isSearchModeNotifier,
          hintText: L10n.of(context)!.whoWouldYouLikeToAdd,
          textEditingController: controller.textEditingController,
          toggleSearchMode: controller.toggleSearchMode,
        ),
      ),
      body: Column(
        children: [
          SelectedParticipantsList(
            newGroupController: controller,
          ),
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: controller
                  .selectedContactsMapNotifier.haveSelectedContactsNotifier,
              builder: (context, haveSelectedContact, child) {
                return Padding(
                  padding: EdgeInsets.only(
                    top: haveSelectedContact ? 0.0 : 8.0,
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
                        onSelectedExternalContact:
                            controller.onExternalContactAction,
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
          onTap: () => controller.moveToNewGroupInfoScreen(),
        ),
      ),
    );
  }
}
