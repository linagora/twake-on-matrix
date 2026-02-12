import 'dart:math';

import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/personal_qr/personal_qr.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_view_mobile_style.dart';
import 'package:fluffychat/presentation/extensions/client_extension.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_qr_code_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

class PersonalQrView extends StatelessWidget {
  const PersonalQrView(this.controller, {super.key});

  final PersonalQrController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final sysColor = LinagoraSysColors.material();
    final client = Matrix.of(context).client;
    final userId = client.userID ?? '';
    final qrData = client.personalInviteUrl;

    return Scaffold(
      appBar: TwakeAppBar(
        title: l10n.yourPersonalQr,
        leading: IconButton(
          onPressed: context.pop,
          icon: const Icon(Icons.arrow_back_ios),
        ),
        context: context,
      ),
      backgroundColor: sysColor.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Align(
                alignment: const Alignment(0, -0.5),
                child: _QrCodeCard(
                  qrKey: controller.qrKey,
                  qrData: qrData,
                  userId: userId,
                  client: client,
                ),
              ),
            ),
            _ActionButtonsSection(qrData: qrData, controller: controller),
          ],
        ),
      ),
    );
  }
}

class _QrCodeCard extends StatelessWidget {
  const _QrCodeCard({
    required this.qrKey,
    required this.qrData,
    required this.userId,
    required this.client,
  });

  final GlobalKey qrKey;
  final String qrData;
  final String userId;
  final Client client;

  @override
  Widget build(BuildContext context) {
    final sysColor = LinagoraSysColors.material();
    final refColor = LinagoraRefColors.material();
    final textTheme = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available space for the card based on width
        final maxWidth = min(constraints.maxWidth, 296.0);
        final availableWidth = maxWidth - 32; // 16px padding on each side
        final widthBasedQrSize = min(
          200.0,
          availableWidth - 32,
        ); // Additional padding inside card

        // Calculate available space based on height
        // Reserve space for: top padding (36 + 44), avatar visible part (36),
        // spacing (8-17), userId text (~48), spacing (16-32), description (~60), bottom padding (24)
        // Total fixed height ranges from ~265px to ~297px depending on spacing scale
        const fixedHeight = 297.0;
        final availableHeight = constraints.maxHeight - fixedHeight;
        final heightBasedQrSize = max(100.0, min(200.0, availableHeight));

        // Use the smaller of the two to ensure it fits in both dimensions
        final qrSize = min(widthBasedQrSize, heightBasedQrSize);

        // Calculate logo size proportionally to QR code
        final logoSize = (qrSize * 0.31).clamp(40.0, 62.0);

        // Calculate responsive spacing based on available height
        // Scale down spacing when height is constrained
        final spacingScale = (constraints.maxHeight / 600.0).clamp(0.5, 1.0);
        final qrToUserIdSpacing = (17.0 * spacingScale).clamp(8.0, 17.0);
        final userIdToDescriptionSpacing = (32.0 * spacingScale).clamp(
          16.0,
          32.0,
        );

        return RepaintBoundary(
          key: qrKey,
          child: Container(
            padding: const EdgeInsets.all(
              8,
            ).add(const EdgeInsets.only(top: 36)),
            constraints: BoxConstraints(maxWidth: maxWidth),
            color: sysColor.surface,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  child: Container(
                    padding: const EdgeInsets.only(
                      top: 44,
                      bottom: 24,
                      left: 16,
                      right: 16,
                    ),
                    decoration: BoxDecoration(
                      color: sysColor.onPrimary,
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            TwakeQrCodeView(data: qrData, size: qrSize),
                            Image.asset(
                              ImagePaths.logoPng,
                              width: logoSize,
                              height: logoSize,
                            ),
                          ],
                        ),
                        SizedBox(height: qrToUserIdSpacing),
                        Text(
                          userId,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.15,
                            color: sysColor.onSurface,
                          ),
                        ),
                        SizedBox(height: userIdToDescriptionSpacing),
                        Text(
                          l10n.personalQrDescription,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                          style: textTheme.bodyMedium?.copyWith(
                            color: refColor.neutral[60],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _ProfileAvatar(client: client),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -36,
      left: 0,
      right: 0,
      child: Align(
        alignment: Alignment.center,
        child: FutureBuilder<Profile>(
          future: client.getProfileFromUserId(
            client.userID ?? '',
            cache: true,
            getFromRooms: false,
          ),
          builder: (context, snapshot) {
            final profile = snapshot.data;
            final displayName =
                profile?.displayName ??
                client.mxid(context).localpart ??
                client.mxid(context);
            return Material(
              elevation:
                  Theme.of(context).appBarTheme.scrolledUnderElevation ?? 4,
              shadowColor: Theme.of(context).appBarTheme.shadowColor,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(AvatarStyle.defaultSize),
              ),
              child: Avatar(
                mxContent: profile?.avatarUrl,
                name: displayName,
                size: 72,
                fontSize: SettingsProfileViewMobileStyle.avatarFontSize,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ActionButtonsSection extends StatelessWidget {
  const _ActionButtonsSection({required this.qrData, required this.controller});

  final String qrData;
  final PersonalQrController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final sysColor = LinagoraSysColors.material();

    return Column(
      children: [
        _ShareQrButton(
          iconData: Icons.send_rounded,
          label: l10n.shareQrCode,
          color: sysColor.onPrimary,
          backgroundColor: sysColor.primary,
          onTap: () => controller.shareQrCode(context),
          rotatePiAngle: -0.25,
        ),
        _ShareQrButton(
          iconData: Icons.copy,
          label: l10n.copyLink,
          color: sysColor.primary,
          backgroundColor: Colors.transparent,
          borderColor: sysColor.primary,
          onTap: () {
            Clipboard.setData(ClipboardData(text: qrData));
            TwakeSnackBar.show(context, l10n.copiedToClipboard);
          },
        ),
        _ShareQrButton(
          iconData: Icons.download_outlined,
          label: l10n.downloadQrCode,
          color: sysColor.primary,
          backgroundColor: Colors.transparent,
          borderColor: sysColor.primary,
          onTap: () => controller.downloadQrCode(context),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ShareQrButton extends StatelessWidget {
  const _ShareQrButton({
    required this.iconData,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
    this.rotatePiAngle = 0,
    this.borderColor,
  });

  final IconData iconData;
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;
  final double rotatePiAngle;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: onTap,
        child: Container(
          height: SettingsProfileViewMobileStyle.bottomButtonHeight,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(
              Radius.circular(
                SettingsProfileViewMobileStyle.bottomButtonRadius,
              ),
            ),
            color: backgroundColor,
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!, width: 1),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.rotate(
                angle: rotatePiAngle * pi,
                child: Icon(iconData, size: 24, color: color),
              ),
              SettingsProfileViewMobileStyle.paddingIconAndText,
              Text(label, style: textTheme.labelLarge?.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
