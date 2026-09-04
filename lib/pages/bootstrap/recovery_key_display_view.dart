import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/bootstrap/verify_device_view_style.dart';
import 'package:twake_chat/pages/key_verification/key_verification_sas_style.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/widgets/context_menu_builder_ios_paste_without_permission.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

/// Shown right after a new recovery key is generated ([BootstrapViewModel]'s
/// `BootstrapRecoveryKeyDisplayState`) — lets the user store it in secure
/// storage and/or copy/share it manually before continuing. Restyled to
/// match the rest of the verify-device flow ([VerifyDeviceViewStyle] /
/// [KeyVerificationSasStyle] tokens); no dedicated Figma design exists for
/// this screen yet.
class RecoveryKeyDisplayView extends StatelessWidget {
  final String recoveryKey;
  final bool supportsSecureStorage;
  final bool storeInSecureStorage;
  final bool recoveryKeyCopied;
  final ValueChanged<bool> onStoreInSecureStorageChanged;
  final VoidCallback onCopyToClipboard;
  final VoidCallback onContinue;

  const RecoveryKeyDisplayView({
    super.key,
    required this.recoveryKey,
    required this.supportsSecureStorage,
    required this.storeInSecureStorage,
    required this.recoveryKeyCopied,
    required this.onStoreInSecureStorageChanged,
    required this.onCopyToClipboard,
    required this.onContinue,
  });

  String _secureStorageLabel(L10n l10n) {
    if (PlatformInfos.isAndroid) {
      return l10n.storeInAndroidKeystore;
    }
    if (PlatformInfos.isIOS || PlatformInfos.isMacOS) {
      return l10n.storeInAppleKeyChain;
    }
    return l10n.storeSecurlyOnThisDevice;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final canContinue = recoveryKeyCopied || storeInSecureStorage;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.key_outlined,
          size: KeyVerificationSasStyle.mascotHeight * 0.4,
          color: VerifyDeviceViewStyle.subtitleColorOf(context),
        ),
        const SizedBox(height: LinagoraSpacing.base * 2),
        Padding(
          padding: VerifyDeviceViewStyle.headingPadding,
          child: Text(
            l10n.recoveryKey,
            textAlign: TextAlign.center,
            style: VerifyDeviceViewStyle.titleStyle(context),
          ),
        ),
        const SizedBox(height: VerifyDeviceViewStyle.gapTitleToSupporting),
        Text(
          l10n.chatBackupDescription,
          textAlign: TextAlign.center,
          style: VerifyDeviceViewStyle.supportingStyle(context),
        ),
        const SizedBox(height: LinagoraSpacing.base * 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: LinagoraStateLayer(
              Theme.of(context).colorScheme.surfaceTint,
            ).opacityLayer1,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            recoveryKey,
            minLines: 2,
            maxLines: 4,
            textAlign: TextAlign.center,
            style: VerifyDeviceViewStyle.supportingStyle(
              context,
            )?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            contextMenuBuilder: mobileTwakeContextMenuBuilder,
          ),
        ),
        const SizedBox(height: VerifyDeviceViewStyle.gapHeadingToOptions),
        if (supportsSecureStorage)
          _CheckRow(
            value: storeInSecureStorage,
            onChanged: onStoreInSecureStorageChanged,
            title: _secureStorageLabel(l10n),
            subtitle: l10n.storeInSecureStorageDescription,
          ),
        _CheckRow(
          value: recoveryKeyCopied,
          onChanged: (_) => onCopyToClipboard(),
          title: l10n.copyToClipboard,
          subtitle: l10n.saveKeyManuallyDescription,
        ),
        const SizedBox(height: LinagoraSpacing.base * 2),
        Material(
          color: canContinue
              ? KeyVerificationSasStyle.primaryColor(context)
              : KeyVerificationSasStyle.primaryColor(
                  context,
                ).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(
            KeyVerificationSasStyle.buttonRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: canContinue ? onContinue : null,
            child: Padding(
              padding: KeyVerificationSasStyle.filledButtonPadding,
              child: SizedBox(
                width: KeyVerificationSasStyle.startChattingButtonWidth,
                child: Center(
                  child: Text(
                    l10n.next,
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

class _CheckRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String subtitle;

  const _CheckRow({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              activeColor: KeyVerificationSasStyle.primaryColor(context),
              onChanged: (checked) => onChanged(checked ?? false),
            ),
            const SizedBox(width: VerifyDeviceViewStyle.settingGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: VerifyDeviceViewStyle.settingTitleStyle(context),
                  ),
                  const SizedBox(height: VerifyDeviceViewStyle.settingTextGap),
                  Text(
                    subtitle,
                    style: VerifyDeviceViewStyle.settingSubtitleStyle(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
