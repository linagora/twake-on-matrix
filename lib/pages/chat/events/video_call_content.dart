import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/utils/clipboard.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class VideoCallContent extends StatelessWidget {
  final String callUrl;

  const VideoCallContent({super.key, required this.callUrl});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final theme = Theme.of(context);
    final compact = getIt.get<ResponsiveUtils>().isMobile(context);
    final buttonSize = compact ? LinagoraButtonSize.xs : LinagoraButtonSize.m;

    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.videoCallStartedTitle,
            style: theme
                .extension<LinagoraTextThemeExtension>()!
                .bodyMedium4
                .copyWith(color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: LinagoraSpacing.base),
          OverflowBar(
            spacing: LinagoraSpacing.base,
            overflowSpacing: LinagoraSpacing.base,
            overflowAlignment: OverflowBarAlignment.start,
            children: [
              LinagoraButton(
                label: l10n.videoCallCopyLink,
                icon: Icons.open_in_new,
                size: buttonSize,
                variant: LinagoraButtonVariant.outlined,
                onPressed: () async {
                  await TwakeClipboard.instance.copyText(callUrl);
                  if (context.mounted) {
                    TwakeSnackBar.show(context, l10n.copiedToClipboard);
                  }
                },
              ),
              LinagoraButton(
                label: l10n.videoCallJoinCall,
                icon: Icons.videocam_outlined,
                size: buttonSize,
                variant: LinagoraButtonVariant.filled,
                onPressed: () => UrlLauncher(context, url: callUrl).launchUrl(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
