import 'package:fluffychat/pages/contacts_tab/contacts_appbar.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_body_view.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_view_style.dart';
import 'package:flutter/material.dart';

class ContactsTabView extends StatelessWidget {
  final ContactsTabController contactsController;

  const ContactsTabView({super.key, required this.contactsController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: ContactsTabViewStyle.preferredSizeAppBar(context),
        child: ContactsAppBar(contactsController),
      ),
      body: ContactsTabBodyView(contactsController),
    );
  }
}
