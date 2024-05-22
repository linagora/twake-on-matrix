import 'dart:convert';

import 'package:fluffychat/pages/bootstrap/bootstrap_dialog.dart';
import 'package:fluffychat/utils/beautify_string_extension.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'settings_security_view.dart';

class SettingsSecurity extends StatefulWidget {
  const SettingsSecurity({super.key});

  @override
  SettingsSecurityController createState() => SettingsSecurityController();
}

class SettingsSecurityController extends State<SettingsSecurity> {
  void changePasswordAccountAction() async {
    final input = await showTextInputDialog(
      useRootNavigator: false,
      context: context,
      title: L10n.of(context)!.changePassword,
      okLabel: L10n.of(context)!.ok,
      cancelLabel: L10n.of(context)!.cancel,
      textFields: [
        DialogTextField(
          hintText: L10n.of(context)!.chooseAStrongPassword,
          obscureText: true,
          minLines: 1,
          maxLines: 1,
        ),
        DialogTextField(
          hintText: L10n.of(context)!.repeatPassword,
          obscureText: true,
          minLines: 1,
          maxLines: 1,
        ),
      ],
    );
    if (input == null) return;
    final success = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () => Matrix.of(context)
          .client
          .changePassword(input.last, oldPassword: input.first),
    );
    if (success.error == null) {
      TwakeSnackBar.show(context, L10n.of(context)!.passwordHasBeenChanged);
    }
  }

  void setAppLockAction() async {
    final currentLock =
        await const FlutterSecureStorage().read(key: SettingKeys.appLockKey);
    if (currentLock?.isNotEmpty ?? false) {
      await AppLock.of(context)!.showLockScreen();
    }
    final newLock = await showTextInputDialog(
      useRootNavigator: false,
      context: context,
      title: L10n.of(context)!.pleaseChooseAPasscode,
      message: L10n.of(context)!.pleaseEnter4Digits,
      cancelLabel: L10n.of(context)!.cancel,
      textFields: [
        DialogTextField(
          validator: (text) {
            if (text!.isEmpty ||
                (text.length == 4 && int.tryParse(text)! >= 0)) {
              return null;
            }
            return L10n.of(context)!.pleaseEnter4Digits;
          },
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLines: 1,
          minLines: 1,
        ),
      ],
    );
    if (newLock != null) {
      await const FlutterSecureStorage()
          .write(key: SettingKeys.appLockKey, value: newLock.single);
      if (newLock.single.isEmpty) {
        AppLock.of(context)!.disable();
      } else {
        AppLock.of(context)!.enable();
      }
    }
  }

  void showBootstrapDialog(BuildContext context) async {
    await BootstrapDialog(
      client: Matrix.of(context).client,
    ).show();
  }

  Future<void> dehydrateAction() => dehydrateDevice(context);

  static Future<void> dehydrateDevice(BuildContext context) async {
    final response = await showOkCancelAlertDialog(
      context: context,
      isDestructiveAction: true,
      title: L10n.of(context)!.dehydrate,
      message: L10n.of(context)!.dehydrateWarning,
    );
    if (response != OkCancelResult.ok) {
      return;
    }
    final file = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        final export = await Matrix.of(context).client.exportDump();
        if (export == null) throw Exception('Export data is null.');

        final exportBytes = Uint8List.fromList(
          const Utf8Codec().encode(export),
        );

        final exportFileName =
            'fluffychat-export-${DateFormat(DateFormat.YEAR_MONTH_DAY).format(DateTime.now())}.fluffybackup';

        return MatrixFile(bytes: exportBytes, name: exportFileName);
      },
    );

    file.result?.downloadFile(context);
  }

  Future<void> copyPublicKey() async {
    Clipboard.setData(
      ClipboardData(text: Matrix.of(context).client.fingerprintKey.beautified),
    );
    TwakeSnackBar.show(
      context,
      L10n.of(context)!.copiedPublicKeyToClipboard,
    );
  }

  @override
  Widget build(BuildContext context) => SettingsSecurityView(this);
}
