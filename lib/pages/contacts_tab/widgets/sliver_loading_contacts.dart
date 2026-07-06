import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/new_private_chat/widget/loading_contact_widget.dart';
import 'package:flutter/material.dart';

class SliverLoadingContacts extends StatelessWidget {
  const SliverLoadingContacts({required this.controller, super.key});

  final ContactsTabController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        controller.presentationContactNotifier,
        controller.presentationPhonebookContactNotifier,
        controller.presentationRecentContactNotifier,
      ]),
      builder: (context, _) {
        if (controller.isWaitingContacts && !controller.hasVisibleContacts) {
          return const SliverToBoxAdapter(child: LoadingContactWidget());
        }
        return const SliverToBoxAdapter();
      },
    );
  }
}
