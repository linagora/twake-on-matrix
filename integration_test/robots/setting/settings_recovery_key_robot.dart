import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'package:fluffychat/generated/l10n/app_localizations.dart';

import '../home_robot.dart';

class SettingsRecoveryKeyRobot extends HomeRobot {
  SettingsRecoveryKeyRobot(super.$);

  PatrolFinder recoveryKeyItem() {
    return $(const Key('recovery_key_settings_item'));
  }

  PatrolFinder recoveryKeyCopyButton() {
    return $(const Key('recovery_key_copy_button'));
  }

  Future<void> waitForRecoveryKeyVisible() async {
    await $.waitUntilVisible(recoveryKeyItem());
  }

  /// Taps the copy button, then confirms the warning dialog by tapping "Copy".
  Future<void> tapCopyAndConfirm() async {
    await recoveryKeyCopyButton().tap();
    await _tapConfirmCopyInDialog();
  }

  /// Taps the recovery key row, then confirms the warning dialog.
  Future<void> tapRowAndConfirm() async {
    await recoveryKeyItem().tap();
    await _tapConfirmCopyInDialog();
  }

  Future<void> _tapConfirmCopyInDialog() async {
    final context = $.tester.element(find.byType(Scaffold).first);
    final l10n = L10n.of(context)!;

    if (Platform.isAndroid) {
      final copyButton = $(
        AlertDialog,
      ).$(TextButton).containing(find.text(l10n.copy.toUpperCase()));
      await $.waitUntilVisible(copyButton);
      await copyButton.tap();
    } else {
      final copyButton = $(
        CupertinoAlertDialog,
      ).$(CupertinoDialogAction).containing(find.text(l10n.copy));
      await $.waitUntilVisible(copyButton);
      await copyButton.tap();
    }
  }

  /// Reads the current text content from the system clipboard.
  Future<String?> getClipboardText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  /// Verifies the snackbar "Recovery key copied to clipboard" is shown.
  Future<void> verifySnackBarIsShown() async {
    final context = $.tester.element(find.byType(Scaffold).first);
    final l10n = L10n.of(context)!;
    await $.waitUntilVisible($(l10n.recoveryKeyCopiedToClipboard));
  }
}
