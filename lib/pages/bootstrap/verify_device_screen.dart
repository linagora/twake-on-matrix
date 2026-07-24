import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/bootstrap/recovery_key_form_view.dart';
import 'package:fluffychat/pages/bootstrap/reset_encryption_confirm_view.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_option.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_view.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_view_style.dart';
import 'package:fluffychat/pages/key_verification/key_verification_emoji_view.dart';
import 'package:fluffychat/pages/key_verification/key_verification_error_view.dart';
import 'package:fluffychat/pages/key_verification/key_verification_success_view.dart';
import 'package:fluffychat/pages/key_verification/key_verification_waiting_view.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/encryption.dart';

class VerifyDeviceScreen extends StatefulWidget {
  final List<VerifyDeviceOption> options;
  final VoidCallback? onRetry;
  final Future<KeyVerification?> Function()? onStartVerification;
  final Future<bool> Function(String recoveryKey)? onVerifyRecoveryKey;
  final String? initialRecoveryKey;
  final Future<bool> Function()? onResetEncryption;

  /// Shows the success view immediately instead of the chooser — used when
  /// the caller's own "Retry automatically" flow (outside this screen's
  /// SAS/recovery-key sub-flows) already completed successfully.
  final bool initialSuccess;

  /// Shows the error view immediately instead of the chooser — used when the
  /// caller's own "Retry automatically" flow failed.
  final bool initialError;

  const VerifyDeviceScreen({
    super.key,
    required this.options,
    this.onRetry,
    this.onStartVerification,
    this.onVerifyRecoveryKey,
    this.initialRecoveryKey,
    this.onResetEncryption,
    this.initialSuccess = false,
    this.initialError = false,
  });

  @override
  State<VerifyDeviceScreen> createState() => _VerifyDeviceScreenState();
}

class _VerifyDeviceScreenState extends State<VerifyDeviceScreen> {
  KeyVerification? _request;
  bool _showRecoveryKeyForm = false;
  late bool _recoveryKeyVerified = widget.initialSuccess;
  late bool _showRetryError = widget.initialError;
  String? _recoveryKeyError;
  bool _showResetConfirm = false;
  bool _resetComplete = false;
  bool _isStartingVerification = false;
  bool _isResetting = false;

  @override
  void didUpdateWidget(covariant VerifyDeviceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // `initialSuccess`/`initialError` reflect the caller's "Retry
    // automatically" outcome, which lands asynchronously well after this
    // screen is first built — without this, the retry's result would never
    // surface because the `late` fields above only evaluate once.
    if (widget.initialSuccess != oldWidget.initialSuccess &&
        widget.initialSuccess) {
      setState(() {
        _recoveryKeyVerified = true;
        _showRetryError = false;
      });
    }
    if (widget.initialError != oldWidget.initialError && widget.initialError) {
      setState(() => _showRetryError = true);
    }
  }

  void _attachRequest(KeyVerification request) {
    _request = request;
    _request!.onUpdate = () {
      if (!mounted) return;
      setState(() {});
    };
    setState(() {});
  }

  Future<void> _startVerification() async {
    final onStartVerification = widget.onStartVerification;
    if (onStartVerification == null || _isStartingVerification) return;
    setState(() => _isStartingVerification = true);
    try {
      final request = await onStartVerification();
      if (request == null || !mounted) return;
      _attachRequest(request);
    } finally {
      if (mounted) setState(() => _isStartingVerification = false);
    }
  }

  Future<bool> _verifyRecoveryKey(String recoveryKey) async {
    final onVerifyRecoveryKey = widget.onVerifyRecoveryKey;
    if (onVerifyRecoveryKey == null) return false;
    final success = await onVerifyRecoveryKey(recoveryKey);
    if (!mounted) return success;
    setState(() {
      if (success) {
        _recoveryKeyVerified = true;
        _recoveryKeyError = null;
      } else {
        _recoveryKeyError = L10n.of(context)!.recoveryKeyDoesntMatch;
      }
    });
    return success;
  }

  Future<void> _resetEncryption() async {
    final onResetEncryption = widget.onResetEncryption;
    if (onResetEncryption == null || _isResetting) return;
    setState(() => _isResetting = true);
    final success = await onResetEncryption();
    if (!mounted) return;
    setState(() {
      _isResetting = false;
      if (success) {
        _resetComplete = true;
      } else {
        _showResetConfirm = false;
      }
    });
  }

  @override
  void dispose() {
    final request = _request;
    if (request != null &&
        ![
          KeyVerificationState.error,
          KeyVerificationState.done,
        ].contains(request.state)) {
      request.cancel('m.user');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils().isMobile(context);
    final content = _buildContent(context, isMobile: isMobile);
    // Blocks back-gesture/Esc/browser-back from dismissing this screen while
    // a reset is in flight — Cancel/close are already disabled, but without
    // this, system-level pop routes would still slip past them.
    return PopScope(
      canPop: !_isResetting,
      child: isMobile
          ? _MobileVerifyDeviceSheet(content: content)
          : _WebVerifyDeviceModal(
              content: content,
              onClose: _webCloseCallback(context),
            ),
    );
  }

  /// The recovery-key form and reset-confirm views share this modal-level
  /// top-right X — anchored to the modal's own edge (matches Figma) rather
  /// than each view drawing its own, which would sit inset by the modal's
  /// content padding instead of flush with the corner.
  VoidCallback? _webCloseCallback(BuildContext context) {
    if (_showRecoveryKeyForm) {
      return () => setState(() => _showRecoveryKeyForm = false);
    }
    if (_showResetConfirm) {
      return _isResetting
          ? null
          : () => setState(() => _showResetConfirm = false);
    }
    return null;
  }

  Widget _buildContent(BuildContext context, {required bool isMobile}) {
    if (_recoveryKeyVerified) {
      return KeyVerificationSuccessView(
        onStartChatting: () => Navigator.of(context).pop(),
      );
    }

    if (_showRetryError) {
      return KeyVerificationErrorView(
        canceledCode: null,
        canceledReason: null,
        description: L10n.of(context)!.retryFailedDescription,
        onClose: () => setState(() => _showRetryError = false),
      );
    }

    if (_resetComplete) {
      return KeyVerificationSuccessView(
        title: L10n.of(context)!.resetCompleteTitle,
        description: L10n.of(context)!.resetCompleteDescription,
        onStartChatting: () => Navigator.of(context).pop(),
      );
    }

    if (_showResetConfirm) {
      return ResetEncryptionConfirmView(
        isResetting: _isResetting,
        onClose: _isResetting
            ? null
            : () => setState(() => _showResetConfirm = false),
        onReset: _resetEncryption,
      );
    }

    if (_showRecoveryKeyForm) {
      return RecoveryKeyFormView(
        onVerify: _verifyRecoveryKey,
        initialValue: widget.initialRecoveryKey,
        initialErrorText: _recoveryKeyError,
      );
    }

    final request = _request;
    if (request == null) {
      return VerifyDeviceView(
        mascotWidth: isMobile
            ? VerifyDeviceViewStyle.mobileMascotWidth
            : VerifyDeviceViewStyle.webMascotWidth,
        mascotHeight: isMobile
            ? VerifyDeviceViewStyle.mobileMascotHeight
            : VerifyDeviceViewStyle.webMascotHeight,
        onRetry: widget.onRetry,
        options: _resolveOptions(context),
      );
    }

    switch (request.state) {
      case KeyVerificationState.askSas:
        if (request.sasTypes.contains('emoji')) {
          return KeyVerificationEmojiView(
            emojis: request.sasEmojis,
            onDontMatch: () => request.rejectSas(),
            onMatch: () => request.acceptSas(),
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

  List<VerifyDeviceOption> _resolveOptions(BuildContext context) {
    return widget.options.map((option) {
      if (option.isUseAnotherDevice && widget.onStartVerification != null) {
        return option.copyWith(
          onTap: _startVerification,
          isLoading: _isStartingVerification,
        );
      }
      if (option.isUseRecoveryKey) {
        return option.copyWith(
          onTap: () => setState(() => _showRecoveryKeyForm = true),
        );
      }
      if (option.isNotPossibleToVerify) {
        return option.copyWith(
          onTap: () => setState(() => _showResetConfirm = true),
        );
      }
      return option;
    }).toList();
  }
}

class _WebVerifyDeviceModal extends StatelessWidget {
  final Widget content;
  final VoidCallback? onClose;

  const _WebVerifyDeviceModal({required this.content, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SizedBox(
          width: VerifyDeviceViewStyle.webModalWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: VerifyDeviceViewStyle.webModalPadding,
                decoration: BoxDecoration(
                  color: VerifyDeviceViewStyle.backgroundColor,
                  borderRadius: BorderRadius.circular(
                    VerifyDeviceViewStyle.webModalRadius,
                  ),
                  boxShadow: VerifyDeviceViewStyle.webModalShadow,
                ),
                child: SizedBox(
                  width: VerifyDeviceViewStyle.webContentWidth,
                  child: content,
                ),
              ),
              if (onClose != null)
                Positioned(
                  top: VerifyDeviceViewStyle.closeButtonInset,
                  right: VerifyDeviceViewStyle.closeButtonInset,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileVerifyDeviceSheet extends StatelessWidget {
  final Widget content;

  const _MobileVerifyDeviceSheet({required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: VerifyDeviceViewStyle.backgroundColor,
            borderRadius: VerifyDeviceViewStyle.sheetRadius,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _DragHandle(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: VerifyDeviceViewStyle.sheetContentPadding,
                    child: content,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: VerifyDeviceViewStyle.dragHandlePadding,
      child: Container(
        width: VerifyDeviceViewStyle.dragHandleWidth,
        height: VerifyDeviceViewStyle.dragHandleHeight,
        decoration: BoxDecoration(
          color: LinagoraStateLayer(
            LinagoraSysColors.material().surfaceTintDark,
          ).opacityLayer3,
          borderRadius: BorderRadius.circular(
            VerifyDeviceViewStyle.dragHandleHeight,
          ),
        ),
      ),
    );
  }
}
