import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/key_verification/key_verification_sas_style.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';
import 'package:twake_chat/widgets/avatar/avatar_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

/// Incoming key-verification request screen.
///
/// Owns its full content — avatar, title, body, and the Reject/Accept
/// actions — so [KeyVerificationDialog] only supplies this as the body and
/// does not layer its own title or button row on top.
class KeyVerificationRequestView extends StatelessWidget {
  final String displayName;
  final Uri? avatarUri;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const KeyVerificationRequestView({
    super.key,
    required this.displayName,
    required this.avatarUri,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Avatar(
          mxContent: avatarUri,
          name: displayName,
          size: AvatarStyle.defaultSize * 2,
        ),
        const SizedBox(height: LinagoraSpacing.base * 2),
        Padding(
          padding: KeyVerificationSasStyle.headingPadding,
          child: Text(
            l10n.newVerificationRequest,
            textAlign: TextAlign.center,
            style: KeyVerificationSasStyle.titleStyle(context),
          ),
        ),
        const SizedBox(height: LinagoraSpacing.base),
        Text(
          l10n.askVerificationRequest(displayName),
          textAlign: TextAlign.center,
          style: KeyVerificationSasStyle.supportingStyle(context),
        ),
        const SizedBox(height: LinagoraSpacing.base * 2),
        Row(
          children: [
            Expanded(
              child: LinagoraButton(
                label: l10n.reject,
                variant: LinagoraButtonVariant.outlined,
                onPressed: onReject,
              ),
            ),
            const SizedBox(width: LinagoraSpacing.base),
            Expanded(
              child: LinagoraButton(label: l10n.accept, onPressed: onAccept),
            ),
          ],
        ),
      ],
    );
  }
}
