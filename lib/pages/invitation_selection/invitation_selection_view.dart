import 'package:fluffychat/pages/new_group/widget/contacts_selection_list.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar.dart';
import 'package:fluffychat/widgets/app_bars/searchable_app_bar_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_fab.dart';
import 'package:fluffychat/widgets/twake_components/twake_smart_refresher.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/pages/invitation_selection/invitation_selection.dart';

class InvitationSelectionView extends StatelessWidget {
  final InvitationSelectionController controller;

  const InvitationSelectionView(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = L10n.of(context)!.inviteContactToGroup(controller.groupName);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: SearchableAppBarStyle.preferredSize(context),
        child: SearchableAppBar(
          searchModeNotifier: controller.isSearchModeNotifier,
          title: title,
          hintText: title,
          focusNode: controller.searchFocusNode,
          textEditingController: controller.textEditingController,
          toggleSearchMode: controller.toggleSearchMode,
        ),
      ),
      body: controller.refreshController == null
          ? null
          : TwakeSmartRefresher(
              controller: controller.refreshController!,
              onRefresh: controller.fetchContacts,
              onLoading: controller.loadMoreContacts,
              child: controller.contactsNotifier == null
                  ? null
                  : ContactsSelectionList(
                      disabledContacts: controller.joinedContacts,
                      contactsNotifier: controller.contactsNotifier!,
                      selectedContactsMapNotifier:
                          controller.selectedContactsMapNotifier,
                      onSelectedContact: controller.onSelectedContact,
                      onSelectedExternalContact:
                          controller.onExternalContactAction,
                    ),
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
          onTap: controller.onSubmit,
        ),
      ),
    );
  }
}
