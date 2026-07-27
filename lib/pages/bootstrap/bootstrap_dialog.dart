import 'package:fluffychat/domain/keychain_sharing/tom_encryption_reset_service.dart';
import 'package:fluffychat/pages/bootstrap/bootstrap_modal_chrome.dart';
import 'package:fluffychat/pages/bootstrap/bootstrap_state.dart';
import 'package:fluffychat/pages/bootstrap/bootstrap_view_model.dart';
import 'package:fluffychat/pages/bootstrap/recovery_key_display_view.dart';
import 'package:fluffychat/pages/bootstrap/tom_bootstrap_dialog.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_option.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_screen.dart';
import 'package:fluffychat/pages/key_verification/key_verification_error_view.dart';
import 'package:fluffychat/pages/key_verification/key_verification_success_view.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matrix/matrix.dart';
import 'package:share_plus/share_plus.dart';

class BootstrapDialog extends ConsumerWidget {
  final bool wipe;
  final Client client;

  const BootstrapDialog({super.key, this.wipe = false, required this.client});

  Future<bool?> show() => TwakeDialog.showDialogFullScreen(
    builder: () => this,
    // BootstrapModalChrome pads its own content; the default SafeArea
    // wrapper here would leave a transparent gap below the mobile bottom
    // sheet instead of letting it reach the true screen edge.
    useSafeArea: false,
  );

  /// Handles "Not possible to verify?" → Reset, matching the pre-verify-
  /// device-flow branching: ToM-backed accounts wipe and re-upload the new
  /// key automatically via [TomEncryptionResetService] — headless, no
  /// dialog of its own; accounts without a ToM backend have nowhere to
  /// recover a lost key from, so they fall back to the legacy local
  /// bootstrap flow via [TomBootstrapDialog].
  Future<bool> _resetEncryption(BuildContext context) async {
    if (Matrix.of(context).twakeSupported) {
      final result = await TomEncryptionResetService(client: client).reset();
      if (!context.mounted) return result == TomEncryptionResetResult.success;
      switch (result) {
        case TomEncryptionResetResult.success:
          break;
        case TomEncryptionResetResult.wipeFailed:
          TwakeSnackBar.show(context, L10n.of(context)!.cannotEnableKeyBackup);
        case TomEncryptionResetResult.uploadFailed:
        case TomEncryptionResetResult.bootstrapFailed:
          TwakeSnackBar.show(context, L10n.of(context)!.oopsSomethingWentWrong);
      }
      return result == TomEncryptionResetResult.success;
    }
    final result = await TomBootstrapDialog(
      client: client,
      wipe: true,
      wipeRecovery: true,
    ).show(context);
    return result == true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = bootstrapViewModelProvider(client, wipe: wipe);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    return switch (state) {
      BootstrapRecoveryKeyDisplayState() => _RecoveryKeyDisplay(
        state: state,
        notifier: notifier,
      ),
      BootstrapVerifyDeviceState() => VerifyDeviceScreen(
        client: client,
        wipe: wipe,
        onResetEncryption: () => _resetEncryption(context),
        options: [
          VerifyDeviceOption(
            icon: Icons.smartphone_outlined,
            title: L10n.of(context)!.useAnotherDevice,
            subtitle: L10n.of(context)!.useAnotherDeviceDescription,
            isUseAnotherDevice: true,
          ),
          VerifyDeviceOption(
            icon: Icons.key_outlined,
            title: L10n.of(context)!.useRecoveryKeyTitle,
            subtitle: L10n.of(context)!.useRecoveryKeyDescription,
            isUseRecoveryKey: true,
          ),
          VerifyDeviceOption(
            icon: Icons.key_off_outlined,
            title: L10n.of(context)!.notPossibleToVerify,
            subtitle: L10n.of(context)!.notPossibleToVerifyDescription,
            isNotPossibleToVerify: true,
          ),
        ],
      ),
      BootstrapLegacyErrorState() => BootstrapModalChrome(
        content: KeyVerificationErrorView(
          canceledCode: null,
          canceledReason: null,
          description: L10n.of(context)!.oopsSomethingWentWrong,
          onClose: () =>
              Navigator.of(context, rootNavigator: false).pop<bool>(false),
        ),
      ),
      BootstrapLegacyDoneState() => BootstrapModalChrome(
        content: KeyVerificationSuccessView(
          title: L10n.of(context)!.yourChatBackupHasBeenSetUp,
          description: L10n.of(context)!.chatBackupSetUpDescription,
          onStartChatting: () =>
              Navigator.of(context, rootNavigator: false).pop<bool>(false),
        ),
      ),
      BootstrapLoadingState() => AlertDialog(
        content: Row(
          children: [
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: CircularProgressIndicator.adaptive(),
              ),
            ),
            Expanded(
              child: Text(
                L10n.of(context)!.loadingPleaseWait,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    };
  }
}

class _RecoveryKeyDisplay extends StatelessWidget {
  final BootstrapRecoveryKeyDisplayState state;
  final BootstrapViewModel notifier;

  const _RecoveryKeyDisplay({required this.state, required this.notifier});

  void _copyToClipboard(BuildContext context) {
    final box = context.findRenderObject() as RenderBox;
    Share.share(
      state.recoveryKey,
      sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
    );
    notifier.confirmRecoveryKeyCopied();
  }

  @override
  Widget build(BuildContext context) {
    return BootstrapModalChrome(
      onClose: () => Navigator.of(context).pop(false),
      content: RecoveryKeyDisplayView(
        recoveryKey: state.recoveryKey,
        supportsSecureStorage: state.supportsSecureStorage,
        storeInSecureStorage: state.storeInSecureStorage,
        recoveryKeyCopied: state.recoveryKeyCopied,
        onStoreInSecureStorageChanged: notifier.setStoreInSecureStorage,
        onCopyToClipboard: () => _copyToClipboard(context),
        onContinue: notifier.continueFromRecoveryKeyDisplay,
      ),
    );
  }
}
