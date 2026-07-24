import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_view_style.dart';
import 'package:fluffychat/pages/key_verification/key_verification_sas_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ResetEncryptionConfirmView extends StatelessWidget {
  static const Color _resetButtonColor = Color(0xFFFF3347);

  final VoidCallback? onClose;
  final VoidCallback onReset;
  final bool isResetting;

  const ResetEncryptionConfirmView({
    super.key,
    required this.onClose,
    required this.onReset,
    this.isResetting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          ImagePaths.mascotResetEncryption,
          width: KeyVerificationSasStyle.mascotWidth,
          height: KeyVerificationSasStyle.mascotHeight,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: KeyVerificationSasStyle.gapMascotToHeading),
        Padding(
          padding: VerifyDeviceViewStyle.headingPadding,
          child: Text(
            L10n.of(context)!.resetEndToEndEncryption,
            textAlign: TextAlign.center,
            style: VerifyDeviceViewStyle.titleStyle(context),
          ),
        ),
        const SizedBox(height: VerifyDeviceViewStyle.gapTitleToSupporting),
        Text(
          L10n.of(context)!.resetEndToEndEncryptionDescription,
          textAlign: TextAlign.center,
          style: VerifyDeviceViewStyle.supportingStyle(context),
        ),
        const SizedBox(height: KeyVerificationSasStyle.gapMascotToHeading),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FilledButton(
              color: _resetButtonColor,
              label: L10n.of(context)!.reset,
              onTap: isResetting ? null : onReset,
              isLoading: isResetting,
            ),
            const SizedBox(width: KeyVerificationSasStyle.gapEmojiButtons),
            _FilledButton(
              color: KeyVerificationSasStyle.primaryColor,
              label: L10n.of(context)!.cancel,
              onTap: isResetting ? null : onClose,
            ),
          ],
        ),
      ],
    );
  }
}

class _FilledButton extends StatelessWidget {
  static const double _loadingIndicatorSize = 20;

  final Color color;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const _FilledButton({
    required this.color,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(KeyVerificationSasStyle.buttonRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: KeyVerificationSasStyle.filledButtonPadding,
          child: isLoading
              ? const SizedBox(
                  width: _loadingIndicatorSize,
                  height: _loadingIndicatorSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: KeyVerificationSasStyle.filledButtonTextStyle(context),
                ),
        ),
      ),
    );
  }
}
