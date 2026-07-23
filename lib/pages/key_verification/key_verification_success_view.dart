import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/key_verification/key_verification_sas_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
        const SizedBox(height: KeyVerificationSasStyle.gapMascotToHeading),
        Padding(
          padding: KeyVerificationSasStyle.headingPadding,
          child: Text(
            title ?? L10n.of(context)!.deviceVerifiedTitle,
            textAlign: TextAlign.center,
            style: KeyVerificationSasStyle.titleStyle(context),
          ),
        ),
        const SizedBox(height: KeyVerificationSasStyle.gapTitleToSupporting),
        Text(
          description ?? L10n.of(context)!.deviceVerifiedDescription,
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
