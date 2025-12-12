import 'package:fluffychat/domain/model/user_info/user_info_visibility.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_enum.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility_view.dart';
import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';
import '../home_robot.dart';

class SettingsContactsVisibilityRobot extends HomeRobot {
  SettingsContactsVisibilityRobot(super.$);

  // Visibility option finders
  PatrolFinder visibilityOption(
    SettingsContactsVisibilityEnum visibilityOption,
  ) {
    return $(Key('visibility_option_${visibilityOption.name}'));
  }

  PatrolFinder visibilityOptionSelected(
    SettingsContactsVisibilityEnum visibilityOption,
  ) {
    return $(Key('visibility_option_selected_${visibilityOption.name}'));
  }

  // Specific visibility options
  PatrolFinder everyoneOption() {
    return visibilityOption(SettingsContactsVisibilityEnum.public);
  }

  PatrolFinder contactsOption() {
    return visibilityOption(SettingsContactsVisibilityEnum.contacts);
  }

  PatrolFinder nobodyOption() {
    return visibilityOption(SettingsContactsVisibilityEnum.private);
  }

  // Selected state finders
  PatrolFinder everyoneSelected() {
    return visibilityOptionSelected(SettingsContactsVisibilityEnum.public);
  }

  PatrolFinder contactsSelected() {
    return visibilityOptionSelected(SettingsContactsVisibilityEnum.contacts);
  }

  PatrolFinder nobodySelected() {
    return visibilityOptionSelected(SettingsContactsVisibilityEnum.private);
  }

  // Visible field option finders
  PatrolFinder visibleFieldOption(VisibleEnum visibleEnum) {
    return $(Key('visible_field_option_${visibleEnum.name}'));
  }

  PatrolFinder visibleFieldOptionSelected(VisibleEnum visibleEnum) {
    return $(Key('visible_field_option_selected_${visibleEnum.name}'));
  }

  // Specific visible field options
  PatrolFinder emailFieldOption() {
    return visibleFieldOption(VisibleEnum.email);
  }

  PatrolFinder phoneNumberFieldOption() {
    return visibleFieldOption(VisibleEnum.phone);
  }

  // Selected state finders for fields
  PatrolFinder emailFieldSelected() {
    return visibleFieldOptionSelected(VisibleEnum.email);
  }

  PatrolFinder phoneNumberFieldSelected() {
    return visibleFieldOptionSelected(VisibleEnum.phone);
  }

  // Actions
  Future<void> selectEveryoneOption() async {
    await everyoneOption().tap();
    await $.waitUntilVisible(everyoneSelected());
  }

  Future<void> selectContactsOption() async {
    await contactsOption().tap();
    await $.waitUntilVisible(contactsSelected());
  }

  Future<void> selectNobodyOption() async {
    await nobodyOption().tap();
    await $.waitUntilVisible(nobodySelected());
  }

  Future<void> toggleEmailField() async {
    await emailFieldOption().tap();
    await $.pumpAndSettle();
  }

  Future<void> togglePhoneNumberField() async {
    await phoneNumberFieldOption().tap();
    await $.pumpAndSettle();
  }

  // Helper methods to check states
  bool isEveryoneSelected() {
    return everyoneSelected().exists;
  }

  bool isContactsSelected() {
    return contactsSelected().exists;
  }

  bool isNobodySelected() {
    return nobodySelected().exists;
  }

  bool isEmailFieldSelected() {
    return emailFieldSelected().exists;
  }

  bool isPhoneNumberFieldSelected() {
    return phoneNumberFieldSelected().exists;
  }

  Future<void> waitForView() async {
    await $.waitUntilVisible($(SettingsContactsVisibilityView));
  }
}
