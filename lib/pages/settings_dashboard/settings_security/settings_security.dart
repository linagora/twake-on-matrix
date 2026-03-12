import 'dart:async';
import 'dart:convert';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/usecase/recovery/get_recovery_words_interactor.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/bootstrap/bootstrap_dialog.dart';
import 'package:fluffychat/presentation/extensions/client_extension.dart';
import 'package:fluffychat/utils/beautify_string_extension.dart';
import 'package:fluffychat/utils/clipboard.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart';

import 'settings_security_view.dart';

class SettingsSecurity extends StatefulWidget {
  const SettingsSecurity({super.key});

  @override
  SettingsSecurityController createState() => SettingsSecurityController();
}

class SettingsSecurityController extends State<SettingsSecurity> {
  StreamSubscription? ignoredUsersStreamSub;

  final ignoredUsersNotifier = ValueNotifier<List<String>>([]);

  Client get client => Matrix.read(context).client;

  /// Future that fetches the recovery key, created once in [initState]
  /// and consumed by a [FutureBuilder] in the view.
  late final Future<String?> recoveryKeyFuture;

  /// Cached recovery key value for the copy action.
  String? _recoveryKey;

  @override
  void initState() {
    listenIgnoredUser();
    recoveryKeyFuture = _fetchRecoveryKey();
    super.initState();
  }

  @override
  void dispose() {
    ignoredUsersStreamSub?.cancel();
    ignoredUsersNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SettingsSecurityView(this);

  /// Fetches the recovery key from the ToM server via [GetRecoveryWordsInteractor].
  /// Returns the key string or null on failure.
  Future<String?> _fetchRecoveryKey() async {
    final result = await getIt.get<GetRecoveryWordsInteractor>().execute();
    return result.fold((failure) => null, (success) {
      _recoveryKey = success.words.words;
      return _recoveryKey;
    });
  }

  /// Copies the recovery key to clipboard after showing a security warning dialog.
  /// The warning informs the user that this secret grants access to all
  /// encrypted messages.
  Future<void> copyRecoveryKey() async {
    final key = _recoveryKey;
    if (key == null) return;

    final l10n = L10n.of(context)!;
    final confirmed = await showOkCancelAlertDialog(
      context: context,
      title: l10n.recoveryKey,
      message: l10n.recoveryKeyWarningMessage,
      okLabel: l10n.copy,
      cancelLabel: l10n.cancel,
      isDestructiveAction: true,
    );
    if (!mounted || confirmed != OkCancelResult.ok) return;

    TwakeClipboard.instance.copyText(key);
    TwakeSnackBar.show(context, l10n.recoveryKeyCopiedToClipboard);
  }

  void changePasswordAccountAction() async {
    final l10n = L10n.of(context)!;
    final input = await showTextInputDialog(
      useRootNavigator: false,
      context: context,
      title: l10n.changePassword,
      okLabel: l10n.ok,
      cancelLabel: l10n.cancel,
      textFields: [
        DialogTextField(
          hintText: l10n.chooseAStrongPassword,
          obscureText: true,
          minLines: 1,
          maxLines: 1,
        ),
        DialogTextField(
          hintText: l10n.repeatPassword,
          obscureText: true,
          minLines: 1,
          maxLines: 1,
        ),
      ],
    );
    if (!mounted || input == null) return;
    final success = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () => client.changePassword(input.last, oldPassword: input.first),
    );
    if (!mounted) return;
    if (success.error == null) {
      TwakeSnackBar.show(context, l10n.passwordHasBeenChanged);
    }
  }

  void setAppLockAction() async {
    final l10n = L10n.of(context)!;
    final currentLock = await const FlutterSecureStorage().read(
      key: SettingKeys.appLockKey,
    );
    final appLock = AppLock.of(context)!;

    if (!mounted) return;
    if (currentLock?.isNotEmpty ?? false) {
      await appLock.showLockScreen();
    }
    if (!mounted) return;
    final newLock = await showTextInputDialog(
      useRootNavigator: false,
      context: context,
      title: l10n.pleaseChooseAPasscode,
      message: l10n.pleaseEnter4Digits,
      cancelLabel: l10n.cancel,
      textFields: [
        DialogTextField(
          validator: (text) {
            if (text!.isEmpty ||
                (text.length == 4 && int.tryParse(text)! >= 0)) {
              return null;
            }
            return l10n.pleaseEnter4Digits;
          },
          keyboardType: .number,
          obscureText: true,
          maxLines: 1,
          minLines: 1,
        ),
      ],
    );
    if (!mounted || newLock == null) return;
    await const FlutterSecureStorage().write(
      key: SettingKeys.appLockKey,
      value: newLock.single,
    );
    if (!mounted) return;
    if (newLock.single.isEmpty) {
      appLock.disable();
    } else {
      appLock.enable();
    }
  }

  void showBootstrapDialog() async {
    await BootstrapDialog(client: client).show();
  }

  Future<void> dehydrateAction() => dehydrateDevice(context);

  static Future<void> dehydrateDevice(BuildContext context) async {
    final l10n = L10n.of(context)!;
    final response = await showOkCancelAlertDialog(
      context: context,
      isDestructiveAction: true,
      title: l10n.dehydrate,
      message: l10n.dehydrateWarning,
    );
    if (response != OkCancelResult.ok) return;

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
    TwakeClipboard.instance.copyText(client.fingerprintKey.beautified);
    TwakeSnackBar.show(context, L10n.of(context)!.copiedPublicKeyToClipboard);
  }

  void listenIgnoredUser() {
    ignoredUsersNotifier.value = client.ignoredUsers;
    ignoredUsersStreamSub = client.ignoredUsersStream.listen((value) {
      ignoredUsersNotifier.value = client.ignoredUsers;
    });
  }
}
