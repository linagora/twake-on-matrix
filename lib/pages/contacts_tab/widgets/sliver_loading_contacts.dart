import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/new_private_chat/widget/loading_contact_widget.dart';
import 'package:flutter/material.dart';

class SliverLoadingContacts extends StatelessWidget {
  const SliverLoadingContacts({required this.controller, super.key});

  final ContactsTabController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.presentationContactNotifier,
      builder: (context, state, _) {
        return state.fold((_) => const SliverToBoxAdapter(), (success) {
          if (success is ContactsLoading) {
            return const SliverToBoxAdapter(child: LoadingContactWidget());
          }
          return const SliverToBoxAdapter();
        });
      },
    );
  }
}
