import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_contact_rows.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../base/core_robot.dart';

class ChatProfileInfoRobot extends CoreRobot {
  ChatProfileInfoRobot(super.$);

  Future<void> verifyDisplayName({required String displayName}) async {
    final displayNameFinder = find.text(displayName);
    expect(displayNameFinder, findsOneWidget);
  }

  Future<void> verifyDisplayMatrixId({required String matrixId}) async {
    final matrixIdFinder = find.text(matrixId);
    expect(matrixIdFinder, findsOneWidget);
  }

  Future<void> verifyEmail({required String email}) async {
    final emailFinder = find.text(email);
    if (email.isEmpty) {
      expect(emailFinder, findsNothing);
      return;
    }
  }

  Future<void> verifyPhoneNumber({required String phoneNumber}) async {
    final phoneNumberFinder = find.text(phoneNumber);
    if (phoneNumber.isEmpty) {
      expect(phoneNumberFinder, findsNothing);
      return;
    }
  }

  /// Get the display name from the ProfileInfoHeader widget
  Future<String> getDisplayName() async {
    // Wait for ProfileInfoHeader to be visible
    await $.waitUntilVisible($(ProfileInfoHeader));

    // Find all Text widgets within ProfileInfoHeader
    final headerFinder = find.descendant(
      of: find.byType(ProfileInfoHeader),
      matching: find.byType(Text),
    );

    // The first Text widget in ProfileInfoHeader is the display name
    if (headerFinder.evaluate().isNotEmpty) {
      final textWidget = $.tester.widget<Text>(headerFinder.first);
      return textWidget.data ?? '';
    }
    return '';
  }

  /// Get the matrix ID from the ProfileInfoContactRows widget
  Future<String> getMatrixId() async {
    // Wait for ProfileInfoContactRows to be visible
    await $.waitUntilVisible($(ProfileInfoContactRows));

    // Find all Text widgets within ProfileInfoContactRows
    final contactRowsFinder = find.descendant(
      of: find.byType(ProfileInfoContactRows),
      matching: find.byType(Text),
    );

    // Look for text that starts with @ (matrix ID pattern)
    for (final element in contactRowsFinder.evaluate()) {
      final textWidget = element.widget as Text;
      final text = textWidget.data ?? '';
      if (text.startsWith('@')) {
        return text;
      }
    }
    return '';
  }

  /// Get email from the ProfileInfoContactRows widget
  Future<String> getEmail() async {
    await $.waitUntilVisible($(ProfileInfoContactRows));

    final contactRowsFinder = find.descendant(
      of: find.byType(ProfileInfoContactRows),
      matching: find.byType(Text),
    );

    // Look for text that contains @ but is not a matrix ID (email pattern)
    for (final element in contactRowsFinder.evaluate()) {
      final textWidget = element.widget as Text;
      final text = textWidget.data ?? '';
      if (text.contains('@') && !text.startsWith('@') && text.contains('.')) {
        return text;
      }
    }
    return '';
  }

  /// Get phone number from the ProfileInfoContactRows widget
  Future<String> getPhoneNumber() async {
    await $.waitUntilVisible($(ProfileInfoContactRows));

    final contactRowsFinder = find.descendant(
      of: find.byType(ProfileInfoContactRows),
      matching: find.byType(Text),
    );

    // Look for text that matches phone number patterns (starts with + or contains only digits)
    for (final element in contactRowsFinder.evaluate()) {
      final textWidget = element.widget as Text;
      final text = textWidget.data ?? '';
      if (text.startsWith('+') ||
          (text.isNotEmpty && RegExp(r'^\d+$').hasMatch(text))) {
        return text;
      }
    }
    return '';
  }
}
