import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_details.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_contact_rows.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_header.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

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

  /// Find the "Leave chat" button in the profile info screen
  PatrolFinder getLeaveChatButton() {
    return $(find.byKey(ChatProfileInfoDetails.leaveChatButtonKey));
  }

  /// Tap on the "Leave chat" button
  Future<void> tapLeaveChatButton() async {
    final leaveChatButton = getLeaveChatButton();
    await leaveChatButton.waitUntilVisible();
    expect(
      leaveChatButton.exists,
      isTrue,
      reason: 'Leave chat button not found',
    );
    await leaveChatButton.tap();
    await $.pumpAndSettle();
  }

  /// Verify the leave chat confirmation dialog is shown
  Future<void> verifyLeaveChatConfirmDialog() async {
    // Wait for the dialog to appear using its key
    await $.waitUntilVisible(
      $(find.byKey(TwakeDialog.showConfirmAlertDialogKey)),
    );

    // Verify the dialog exists
    final dialogFinder = find.byKey(TwakeDialog.showConfirmAlertDialogKey);
    expect(dialogFinder, findsOneWidget, reason: 'Leave chat dialog not found');
  }

  /// Confirm leaving the chat in the dialog
  Future<void> confirmLeaveChat() async {
    // Find the dialog using the key we already verified exists
    final dialogFinder = find.byKey(TwakeDialog.showConfirmAlertDialogKey);

    // Try to find the "Leave" button by text (hardcoded for test reliability)
    final leaveButtonByText = find.descendant(
      of: dialogFinder,
      matching: find.text('Leave'),
    );

    if (leaveButtonByText.evaluate().isNotEmpty) {
      await $(leaveButtonByText).tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));
      return;
    }

    // Fallback: Find all buttons and tap the confirm button (positive action)
    final confirmButtons = find.descendant(
      of: dialogFinder,
      matching: find.byWidgetPredicate(
        (widget) => widget is TextButton || widget is ElevatedButton,
      ),
    );

    if (confirmButtons.evaluate().length >= 2) {
      // The confirm button is typically the second button
      await $(confirmButtons.at(1)).tap();
    } else if (confirmButtons.evaluate().isNotEmpty) {
      await $(confirmButtons.first).tap();
    }
    await $.pumpAndSettle(timeout: const Duration(seconds: 5));
  }

  /// Navigate back from profile info screen
  Future<void> navigateBack() async {
    final backButton = $(AppBar).$(IconButton).first;
    await backButton.tap();
    await $.pumpAndSettle();
  }
}
