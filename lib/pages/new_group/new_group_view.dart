import 'package:fluffychat/pages/new_group/widget/contacts_selection_list.dart';
import 'package:fluffychat/pages/new_group/widget/selected_participants_list.dart';
import 'package:fluffychat/pages/new_private_chat/widget/new_private_appbar.dart';
import 'package:fluffychat/pages/new_private_chat/widget/new_private_appbar_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_fab.dart';
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
        preferredSize:
            Size.fromHeight(NewPrivateAppBarStyle.appbarHeight(context)),
        child: NewPrivateAppBar(
          focusNode: controller.searchFocusNode,
          title: L10n.of(context)!.newGroupChat,
          searchModeNotifier: controller.isSearchModeNotifier,
          hintText: L10n.of(context)!.whoWouldYouLikeToAdd,
          onCloseSearchTapped: controller.onCloseSearchTapped,
          openSearchBar: controller.openSearchBar,
        ),
      ),
      body: Column(
        children: [
          SelectedParticipantsList(
            newGroupController: controller,
          ),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              controller: controller.scrollController,
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
                child: ContactsSelectionList(
                  newGroupController: controller,
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
