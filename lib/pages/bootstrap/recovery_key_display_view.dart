import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_view_style.dart';
import 'package:fluffychat/pages/key_verification/key_verification_sas_style.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/context_menu_builder_ios_paste_without_permission.dart';
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

  String _secureStorageLabel(BuildContext context) {
    if (PlatformInfos.isAndroid) {
      return L10n.of(context)!.storeInAndroidKeystore;
    }
    if (PlatformInfos.isIOS || PlatformInfos.isMacOS) {
      return L10n.of(context)!.storeInAppleKeyChain;
    }
    return L10n.of(context)!.storeSecurlyOnThisDevice;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.key_outlined,
          size: KeyVerificationSasStyle.mascotHeight * 0.4,
          color: VerifyDeviceViewStyle.subtitleColor,
        ),
        const SizedBox(height: LinagoraSpacing.base * 2),
        Padding(
          padding: VerifyDeviceViewStyle.headingPadding,
          child: Text(
            L10n.of(context)!.recoveryKey,
            textAlign: TextAlign.center,
            style: VerifyDeviceViewStyle.titleStyle(context),
          ),
        ),
        const SizedBox(height: VerifyDeviceViewStyle.gapTitleToSupporting),
        Text(
          L10n.of(context)!.chatBackupDescription,
          textAlign: TextAlign.center,
          style: VerifyDeviceViewStyle.supportingStyle(context),
        ),
        const SizedBox(height: LinagoraSpacing.base * 2),
        TextField(
          minLines: 2,
          maxLines: 4,
          readOnly: true,
          textAlign: TextAlign.center,
          style: VerifyDeviceViewStyle.supportingStyle(
            context,
          )?.copyWith(color: Theme.of(context).colorScheme.onSurface),
          contextMenuBuilder: mobileTwakeContextMenuBuilder,
          controller: TextEditingController(text: recoveryKey),
          decoration: InputDecoration(
            filled: true,
            fillColor: LinagoraStateLayer(
              Theme.of(context).colorScheme.surfaceTint,
            ).opacityLayer1,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: VerifyDeviceViewStyle.gapHeadingToOptions),
        if (supportsSecureStorage)
          _CheckRow(
            value: storeInSecureStorage,
            onChanged: onStoreInSecureStorageChanged,
            title: _secureStorageLabel(context),
            subtitle: L10n.of(context)!.storeInSecureStorageDescription,
          ),
        _CheckRow(
          value: recoveryKeyCopied,
          onChanged: (_) => onCopyToClipboard(),
          title: L10n.of(context)!.copyToClipboard,
          subtitle: L10n.of(context)!.saveKeyManuallyDescription,
        ),
        const SizedBox(height: LinagoraSpacing.base * 2),
        Material(
          color: KeyVerificationSasStyle.primaryColor(context),
          borderRadius: BorderRadius.circular(
            KeyVerificationSasStyle.buttonRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onContinue,
            child: Padding(
              padding: KeyVerificationSasStyle.filledButtonPadding,
              child: SizedBox(
                width: KeyVerificationSasStyle.startChattingButtonWidth,
                child: Center(
                  child: Text(
                    L10n.of(context)!.next,
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
