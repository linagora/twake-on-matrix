import 'package:fluffychat/pages/contacts_tab/contacts_appbar.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_body_view.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class ContactsTabView extends StatelessWidget {
  final ContactsTabController contactsController;

  const ContactsTabView({super.key, required this.contactsController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          ResponsiveUtils().isMobile(context) ? 120 : 96,
        ),
        child: ContactsAppBar(contactsController),
      ),
      body: ContactsTabBodyView(contactsController),
    );
  }
}
