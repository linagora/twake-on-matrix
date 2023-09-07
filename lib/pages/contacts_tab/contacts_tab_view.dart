import 'package:fluffychat/pages/contacts_tab/contacts_appbar.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_body_view.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_view_style.dart';
import 'package:flutter/material.dart';

class ContactsTabView extends StatelessWidget {
  final ContactsTabController contactsController;
  final Widget? bottomNavigationBar;

  const ContactsTabView({
    super.key,
    required this.contactsController,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: ContactsTabViewStyle.preferredSizeAppBar,
        child: ContactsAppBar(
          isSearchModeNotifier: contactsController.isSearchModeNotifier,
          searchFocusNode: contactsController.searchFocusNode,
          clearSearchBar: contactsController.clearSearchBar,
          textEditingController: contactsController.textEditingController,
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.black.withOpacity(0.15),
            ),
            ContactsTabBodyView(contactsController),
          ],
        ),
      ),
    );
  }
}
