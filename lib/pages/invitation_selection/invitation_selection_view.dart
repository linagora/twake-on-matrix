import 'package:fluffychat/pages/new_group/widget/contacts_selection_list.dart';
import 'package:fluffychat/widgets/app_bars/searchable_appbar.dart';
import 'package:fluffychat/widgets/app_bars/searchable_appbar_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_fab.dart';
import 'package:fluffychat/widgets/twake_components/twake_smart_refresher.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/pages/invitation_selection/invitation_selection.dart';
import 'package:fluffychat/widgets/matrix.dart';

class InvitationSelectionView extends StatelessWidget {
  final InvitationSelectionController controller;

  const InvitationSelectionView(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final room = Matrix.of(context).client.getRoomById(controller.roomId!)!;
    final groupName = room.name.isEmpty ? L10n.of(context)!.group : room.name;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: SearchableAppBarStyle.preferredSize(context),
        child: SearchableAppBar(
          searchModeNotifier: controller.isSearchModeNotifier,
          title: L10n.of(context)!.inviteContactToGroup(groupName),
          hintText: L10n.of(context)!.inviteContactToGroup(groupName),
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
          onTap: controller.inviteAction,
        ),
      ),
    );
  }
}
