import 'package:fluffychat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_enum.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsContactsVisibility extends StatefulWidget {
  const SettingsContactsVisibility({super.key});

  @override
  State<SettingsContactsVisibility> createState() =>
      SettingsContactsVisibilityController();
}

class SettingsContactsVisibilityController
    extends State<SettingsContactsVisibility> {
  void onBack() {
    context.go('/rooms/security');
  }

  List<SettingsContactsVisibilityEnum> visibilityOptions = [
    SettingsContactsVisibilityEnum.everyone,
    SettingsContactsVisibilityEnum.myContacts,
    SettingsContactsVisibilityEnum.nobody,
  ];

  @override
  Widget build(BuildContext context) {
    return SettingsContactsVisibilityView(controller: this);
  }
}
