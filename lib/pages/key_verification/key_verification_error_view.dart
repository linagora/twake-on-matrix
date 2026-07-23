import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/key_verification/key_verification_sas_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class KeyVerificationErrorView extends StatelessWidget {
  final String? canceledCode;
  final String? canceledReason;
  final VoidCallback onClose;

  /// Overrides the default cancelled/rejected copy — used by the
  /// auto-retry-failed case, where "please try again" would be misleading
  /// since Close just returns to the chooser instead of retrying.
  final String? description;

  const KeyVerificationErrorView({
    super.key,
    required this.canceledCode,
    required this.canceledReason,
    required this.onClose,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          ImagePaths.mascotVerificationFailed,
          width: KeyVerificationSasStyle.mascotWidth,
          height: KeyVerificationSasStyle.mascotHeight,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: KeyVerificationSasStyle.gapMascotToHeading),
        Padding(
          padding: KeyVerificationSasStyle.headingPadding,
          child: Text(
            L10n.of(context)!.verificationFailedTitle,
            textAlign: TextAlign.center,
            style: KeyVerificationSasStyle.titleStyle(context),
          ),
        ),
        const SizedBox(height: KeyVerificationSasStyle.gapTitleToSupporting),
        Text(
          description ?? L10n.of(context)!.verificationFailedDescription,
          textAlign: TextAlign.center,
          style: KeyVerificationSasStyle.supportingStyle(context),
        ),
        const SizedBox(height: KeyVerificationSasStyle.gapMascotToHeading),
        Material(
          color: KeyVerificationSasStyle.primaryColor,
          borderRadius: BorderRadius.circular(
            KeyVerificationSasStyle.buttonRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onClose,
            child: Padding(
              padding: KeyVerificationSasStyle.filledButtonPadding,
              child: SizedBox(
                width: KeyVerificationSasStyle.startChattingButtonWidth,
                child: Center(
                  child: Text(
                    L10n.of(context)!.close,
                    style: KeyVerificationSasStyle.filledButtonTextStyle(
                      context,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
