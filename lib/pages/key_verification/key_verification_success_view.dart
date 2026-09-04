import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/key_verification/key_verification_sas_style.dart';
import 'package:twake_chat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class KeyVerificationSuccessView extends StatelessWidget {
  final VoidCallback onStartChatting;
  final String? title;
  final String? description;

  const KeyVerificationSuccessView({
    super.key,
    required this.onStartChatting,
    this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          ImagePaths.mascotDeviceVerified,
          width: KeyVerificationSasStyle.verifiedMascotWidth,
          height: KeyVerificationSasStyle.verifiedMascotHeight,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: LinagoraSpacing.base * 2),
        Padding(
          padding: KeyVerificationSasStyle.headingPadding,
          child: Text(
            title ?? L10n.of(context)!.deviceVerifiedTitle,
            textAlign: TextAlign.center,
            style: KeyVerificationSasStyle.titleStyle(context),
          ),
        ),
        const SizedBox(height: LinagoraSpacing.base),
        Text(
          description ?? L10n.of(context)!.deviceVerifiedDescription,
          textAlign: TextAlign.center,
          style: KeyVerificationSasStyle.supportingStyle(context),
        ),
        const SizedBox(height: LinagoraSpacing.base * 2),
        Material(
          color: KeyVerificationSasStyle.primaryColor(context),
          borderRadius: BorderRadius.circular(
            KeyVerificationSasStyle.buttonRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onStartChatting,
            child: Padding(
              padding: KeyVerificationSasStyle.filledButtonPadding,
              child: SizedBox(
                width: KeyVerificationSasStyle.startChattingButtonWidth,
                child: Center(
                  child: Text(
                    L10n.of(context)!.startChatting,
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
