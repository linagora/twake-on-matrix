import 'package:fluffychat/pages/contacts/presentation/model/presentation_contact.dart';
import 'package:fluffychat/pages/new_group/widget/contacts_selection_list.dart';
import 'package:fluffychat/pages/new_group/widget/selected_participants_list.dart';
import 'package:fluffychat/pages/new_private_chat/widget/search_contact_appbar.dart';
import 'package:fluffychat/widgets/twake_components/twake_fab.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/pages/new_group/new_group.dart';
import 'package:matrix/matrix.dart';

class NewGroupView extends StatelessWidget {
  final NewGroupController controller;

  const NewGroupView(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SearchContactAppBar(
          title: L10n.of(context)!.newGroupChat,
          searchContactsController: controller.searchContactsController,
          onCloseSearchBar: () => controller.fetchContactsController.fetchCurrentTomContacts(),
          hintText: L10n.of(context)!.whoWouldYouLikeToAdd,
        ),
      ),
      body: Column(
        children: [
          SelectedParticipantsList(newGroupController: controller,),
          Expanded(
            child: SingleChildScrollView(
              child: ValueListenableBuilder<bool>(
                valueListenable: controller.haveSelectedContactsNotifier,
                builder: (context, haveSelectedContact, child) {
                  return Padding(
                    padding: EdgeInsets.only(top: haveSelectedContact ? 0.0 : 8.0,),
                    child: child,
                  );
                },
                child: ContactsSelectionList(newGroupController: controller,),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: controller.haveSelectedContactsNotifier,
        builder: (context, haveSelectedContacts, child) {
          if (!haveSelectedContacts) {
            return const SizedBox.shrink();
          }
          return child!;
        },
        child: TwakeFloatingActionButton(
          icon: Icons.arrow_forward,
          onTap: () {
            Logs().d("NewGroupView::FloatingActionButton: tapped");
          },
        ),
      ),
    );
  }
}
