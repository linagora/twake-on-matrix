import 'package:fluffychat/pages/contacts_tab/contacts_appbar.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_body_view.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_view_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

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
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: ContactsTabViewStyle.preferredSizeAppBar,
        child: ContactsAppBar(
          isSearchModeNotifier: contactsController.isSearchModeNotifier,
          searchFocusNode: contactsController.searchFocusNode,
          clearSearchBar: contactsController.closeSearchBar,
          textEditingController: contactsController.textEditingController,
        ),
      ),
      backgroundColor: LinagoraSysColors.material().onPrimary,
      bottomNavigationBar: bottomNavigationBar,
      body: ContactsTabBodyView(contactsController),
    );
  }
}
