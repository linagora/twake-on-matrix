import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/bootstrap/bootstrap_modal_chrome.dart';
import 'package:fluffychat/pages/bootstrap/recovery_key_form_view.dart';
import 'package:fluffychat/pages/bootstrap/reset_encryption_confirm_view.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_option.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_state.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_view.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_view_model.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_view_style.dart';
import 'package:fluffychat/pages/key_verification/key_verification_emoji_view.dart';
import 'package:fluffychat/pages/key_verification/key_verification_error_view.dart';
import 'package:fluffychat/pages/key_verification/key_verification_success_view.dart';
import 'package:fluffychat/pages/key_verification/key_verification_waiting_view.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';

class VerifyDeviceScreen extends ConsumerWidget {
  final Client client;
  final bool wipe;
  final List<VerifyDeviceOption> options;
  final Future<bool> Function() onResetEncryption;

  const VerifyDeviceScreen({
    super.key,
    required this.client,
    required this.wipe,
    required this.options,
    required this.onResetEncryption,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = verifyDeviceViewModelProvider(client, wipe: wipe);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final isMobile = ResponsiveUtils().isMobile(context);
    final content = _buildContent(
      context,
      state: state,
      notifier: notifier,
      isMobile: isMobile,
    );
    final isResetting =
        state is VerifyDeviceResetConfirmState && state.isResetting;
    // Blocks back-gesture/Esc/browser-back from dismissing this screen while
    // a reset is in flight — Cancel/close are already disabled, but without
    // this, system-level pop routes would still slip past them.
    return PopScope(
      canPop: !isResetting,
      child: BootstrapModalChrome(
        content: content,
        onClose: _webCloseCallback(state, notifier),
      ),
    );
  }

  /// The recovery-key form and reset-confirm views share this modal-level
  /// top-right X — anchored to the modal's own edge (matches Figma) rather
  /// than each view drawing its own, which would sit inset by the modal's
  /// content padding instead of flush with the corner.
  VoidCallback? _webCloseCallback(
    VerifyDeviceUiState state,
    VerifyDeviceViewModel notifier,
  ) {
    if (state is VerifyDeviceRecoveryKeyFormState) {
      return notifier.closeRecoveryKeyForm;
    }
    if (state is VerifyDeviceResetConfirmState) {
      return state.isResetting ? null : notifier.closeResetConfirm;
    }
    return null;
  }

  Widget _buildContent(
    BuildContext context, {
    required VerifyDeviceUiState state,
    required VerifyDeviceViewModel notifier,
    required bool isMobile,
  }) {
    switch (state) {
      case VerifyDeviceSuccessState():
        return KeyVerificationSuccessView(
          onStartChatting: () => Navigator.of(context).pop(),
        );
      case VerifyDeviceRetryErrorState():
        return KeyVerificationErrorView(
          canceledCode: null,
          canceledReason: null,
          description: L10n.of(context)!.retryFailedDescription,
          onClose: notifier.dismissRetryError,
        );
      case VerifyDeviceResetCompleteState():
        return KeyVerificationSuccessView(
          title: L10n.of(context)!.resetCompleteTitle,
          description: L10n.of(context)!.resetCompleteDescription,
          onStartChatting: () => Navigator.of(context).pop(),
        );
      case VerifyDeviceResetConfirmState(:final isResetting):
        return ResetEncryptionConfirmView(
          isResetting: isResetting,
          onClose: isResetting ? null : notifier.closeResetConfirm,
          onReset: () => notifier.resetEncryption(onResetEncryption),
        );
      case VerifyDeviceRecoveryKeyFormState(
        :final initialValue,
        :final errorText,
      ):
        return RecoveryKeyFormView(
          onVerify: (recoveryKey) async {
            final success = await notifier.verifyRecoveryKey(recoveryKey);
            if (!success) {
              notifier.setRecoveryKeyError(
                L10n.of(context)!.recoveryKeyDoesntMatch,
              );
            }
            return success;
          },
          initialValue: initialValue,
          initialErrorText: errorText,
        );
      case VerifyDeviceSasState(:final request):
        return _buildSasContent(context, request: request, notifier: notifier);
      case VerifyDeviceChooserState():
        return VerifyDeviceView(
          mascotWidth: isMobile
              ? VerifyDeviceViewStyle.mobileMascotWidth
              : VerifyDeviceViewStyle.webMascotWidth,
          mascotHeight: isMobile
              ? VerifyDeviceViewStyle.mobileMascotHeight
              : VerifyDeviceViewStyle.webMascotHeight,
          onRetry: notifier.retry,
          options: notifier.resolveOptions(options),
        );
    }
  }

  Widget _buildSasContent(
    BuildContext context, {
    required KeyVerification request,
    required VerifyDeviceViewModel notifier,
  }) {
    switch (request.state) {
      case KeyVerificationState.askSas:
        if (request.sasTypes.contains('emoji')) {
          return KeyVerificationEmojiView(
            emojis: request.sasEmojis,
            onDontMatch: notifier.rejectSas,
            onMatch: notifier.acceptSas,
          );
        }
        return const KeyVerificationWaitingView();
      case KeyVerificationState.done:
        return KeyVerificationSuccessView(
          onStartChatting: () => Navigator.of(context).pop(),
        );
      case KeyVerificationState.error:
        return KeyVerificationErrorView(
          canceledCode: request.canceledCode,
          canceledReason: request.canceledReason,
          onClose: () => Navigator.of(context).pop(),
        );
      case KeyVerificationState.askChoice:
      case KeyVerificationState.waitingAccept:
      case KeyVerificationState.waitingSas:
      case KeyVerificationState.askAccept:
      case KeyVerificationState.askSSSS:
      case KeyVerificationState.showQRSuccess:
      case KeyVerificationState.confirmQRScan:
        return const KeyVerificationWaitingView();
    }
  }
}
