import 'package:fluffychat/pages/contacts_tab/contacts_appbar.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_body_view.dart';
import 'package:flutter/material.dart';

class ContactsTabView extends StatelessWidget {
  final ContactsTabController contactsController;

  const ContactsTabView({super.key, required this.contactsController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ContactsAppBar(contactsController),
      body: ContactsTabBodyView(contactsController),
    );
  }
}
