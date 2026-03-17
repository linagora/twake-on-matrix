import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_view_style.dart';
import 'package:fluffychat/pages/contacts_tab/empty_contacts_body.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact_success.dart';
import 'package:flutter/material.dart';

class SliverEmptyContacts extends StatelessWidget {
  const SliverEmptyContacts({required this.controller, super.key});

  final ContactsTabController controller;

  bool _isLoading() => controller.presentationContactNotifier.value.fold(
    (_) => false,
    (s) => s is ContactsLoading,
  );

  bool _hasContactsData() => controller.presentationContactNotifier.value.fold(
    (_) => false,
    (s) =>
        (s is PresentationContactsSuccess && s.contacts.isNotEmpty) ||
        s is PresentationExternalContactSuccess,
  );

  bool _hasPhonebookData() =>
      controller.presentationPhonebookContactNotifier.value.fold(
        (_) => false,
        (s) => s is PresentationContactsSuccess && s.contacts.isNotEmpty,
      );

  bool _hasRecentData() =>
      controller.presentationRecentContactNotifier.value.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        controller.presentationContactNotifier,
        controller.presentationPhonebookContactNotifier,
        controller.presentationRecentContactNotifier,
      ]),
      builder: (context, _) {
        if (_isLoading() ||
            _hasContactsData() ||
            _hasPhonebookData() ||
            _hasRecentData()) {
          return const SliverToBoxAdapter();
        }
        final keyword = controller.textEditingController.text;
        if (keyword.isEmpty) {
          return const SliverToBoxAdapter(child: EmptyContactBody());
        }
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(
              left: ContactsTabViewStyle.padding,
              top: ContactsTabViewStyle.padding,
            ),
            child: NoContactsFound(keyword: keyword),
          ),
        );
      },
    );
  }
}
