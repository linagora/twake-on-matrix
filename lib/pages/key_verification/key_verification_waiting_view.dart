import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/key_verification/key_verification_sas_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class KeyVerificationWaitingView extends StatelessWidget {
  const KeyVerificationWaitingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          ImagePaths.mascotVerifyDevices,
          width: KeyVerificationSasStyle.mascotWidth,
          height: KeyVerificationSasStyle.mascotHeight,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: KeyVerificationSasStyle.gapMascotToSpinner),
        SizedBox(
          width: KeyVerificationSasStyle.spinnerSize,
          height: KeyVerificationSasStyle.spinnerSize,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: KeyVerificationSasStyle.spinnerColor(context),
          ),
        ),
        const SizedBox(height: KeyVerificationSasStyle.gapSpinnerToHeading),
        Padding(
          padding: KeyVerificationSasStyle.headingPadding,
          child: Text(
            L10n.of(context)!.checkYourOtherDevice,
            textAlign: TextAlign.center,
            style: KeyVerificationSasStyle.titleStyle(context),
          ),
        ),
        const SizedBox(height: KeyVerificationSasStyle.gapTitleToSupporting),
        Text(
          L10n.of(context)!.checkYourOtherDeviceDescription,
          textAlign: TextAlign.center,
          style: KeyVerificationSasStyle.supportingStyle(context),
        ),
      ],
    );
  }
}
