import 'package:twake_chat/pages/contacts_tab/contacts_appbar.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_tab.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_tab_body_view.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_tab_view_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ContactsTabView extends StatelessWidget {
  final ContactsTabController contactsController;
  final Widget? bottomNavigationBar;

  /// The avatar of the phone app bar opens Settings.
  final VoidCallback? onOpenSettings;

  const ContactsTabView({
    super.key,
    required this.contactsController,
    this.bottomNavigationBar,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: ContactsTabViewStyle.preferredSizeAppBar,
        child: ContactsAppBar(
          isSearchModeNotifier: contactsController.isSearchModeNotifier,
          searchFocusNode: contactsController.searchFocusNode,
          clearSearchBar: contactsController.closeSearchBar,
          textEditingController: contactsController.textEditingController,
          onOpenSettings: onOpenSettings,
        ),
      ),
      backgroundColor: LinagoraSysColors.material().onPrimary,
      bottomNavigationBar: bottomNavigationBar,
      body: ContactsTabBodyView(contactsController),
    );
  }
}
