import 'dart:math';

import 'package:fluffychat/config/app_config.dart';
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
import 'package:share_plus/share_plus.dart';

class PersonalQrView extends StatelessWidget {
  const PersonalQrView(this.controller, {super.key});

  final PersonalQrController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final sysColor = LinagoraSysColors.material();
    final client = Matrix.of(context).client;
    final userId = client.userID ?? '';
    final qrData = '${AppConfig.inviteLinkPrefix}$userId';

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
              child: Center(
                child: _QrCodeCard(
                  qrKey: controller.qrKey,
                  qrData: qrData,
                  userId: userId,
                  client: client,
                ),
              ),
            ),
            _ActionButtonsSection(
              qrData: qrData,
              controller: controller,
            ),
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

    return RepaintBoundary(
      key: qrKey,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        child: Container(
          padding: const EdgeInsets.only(top: 36),
          color: sysColor.surface,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.only(top: 44, bottom: 24),
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
                        TwakeQrCodeView(data: qrData, size: 200),
                        Image.asset(
                          ImagePaths.logoPng,
                          width: 62,
                          height: 62,
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    Text(
                      userId,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.15,
                        color: sysColor.onSurface,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 264,
                      child: Text(
                        l10n.personalQrDescription,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: refColor.neutral[60],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _ProfileAvatar(client: client),
            ],
          ),
        ),
      ),
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
            client.userID!,
            cache: true,
            getFromRooms: false,
          ),
          builder: (context, snapshot) {
            final profile = snapshot.data;
            final displayName = profile?.displayName ??
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
  const _ActionButtonsSection({
    required this.qrData,
    required this.controller,
  });

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
          onTap: () => Share.share(qrData),
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
                child: Icon(
                  iconData,
                  size: 24,
                  color: color,
                ),
              ),
              SettingsProfileViewMobileStyle.paddingIconAndText,
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
