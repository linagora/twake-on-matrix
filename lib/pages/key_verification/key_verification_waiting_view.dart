import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/key_verification/key_verification_sas_style.dart';
import 'package:twake_chat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

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
        const SizedBox(height: LinagoraSpacing.base * 2),
        SizedBox(
          width: KeyVerificationSasStyle.spinnerSize,
          height: KeyVerificationSasStyle.spinnerSize,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: KeyVerificationSasStyle.spinnerColor(context),
          ),
        ),
        const SizedBox(height: LinagoraSpacing.base),
        Padding(
          padding: KeyVerificationSasStyle.headingPadding,
          child: Text(
            L10n.of(context)!.checkYourOtherDevice,
            textAlign: TextAlign.center,
            style: KeyVerificationSasStyle.titleStyle(context),
          ),
        ),
        const SizedBox(height: LinagoraSpacing.base),
        Text(
          L10n.of(context)!.checkYourOtherDeviceDescription,
          textAlign: TextAlign.center,
          style: KeyVerificationSasStyle.supportingStyle(context),
        ),
      ],
    );
  }
}
