import 'package:flutter/material.dart';

import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/bootstrap/bootstrap_modal_chrome.dart';
import 'package:twake_chat/pages/device_settings/session_summary.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';

class SessionAllActionsDialog {
  const SessionAllActionsDialog._();

  static Future<void> show(
    BuildContext context, {
    required SessionSummary session,
    required VoidCallback onChangeName,
    VoidCallback? onStartVerification,
    VoidCallback? onRemove,
  }) {
    return TwakeDialog.showDialogFullScreen(
      useSafeArea: false,
      builder: () => BootstrapModalChrome(
        content: SessionAllActionsView(
          session: session,
          onChangeName: onChangeName,
          onStartVerification: onStartVerification,
          onRemove: onRemove,
        ),
      ),
    );
  }
}

class SessionAllActionsView extends StatelessWidget {
  static const double _avatarSize = 56;
  static const double _gapAvatarToText = LinagoraSpacing.base;
  static const double _gapHeaderToDivider = LinagoraSpacing.base;
  static const double _gapHeaderToActions = LinagoraSpacing.base * 2;
  static const double _gapActionsToCancel = LinagoraSpacing.base * 2;

  final SessionSummary session;
  final VoidCallback onChangeName;
  final VoidCallback? onStartVerification;
  final VoidCallback? onRemove;

  const SessionAllActionsView({
    super.key,
    required this.session,
    required this.onChangeName,
    this.onStartVerification,
    this.onRemove,
  });

  void _runAfterClose(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => action());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final colors = LinagoraSysColors.material();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SessionDeviceAvatar(
              icon: session.platformIcon,
              verified: session.verified,
              size: _avatarSize,
            ),
            const SizedBox(width: _gapAvatarToText),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    session.deviceName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onBackground,
                    ),
                  ),
                  Text(
                    session.lastActiveText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: LinagoraRefColors.material().tertiary[30],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: _gapHeaderToDivider),
        const _HeaderDivider(),
        const SizedBox(height: _gapHeaderToActions),
        LinagoraSettingItem(
          leadingIcon: Icons.edit,
          title: l10n.changeDeviceName,
          subtitle: l10n.editDisplayNameForSession,
          showDivider: true,
          crossAxisAlignment: CrossAxisAlignment.start,
          onTap: () => _runAfterClose(context, onChangeName),
        ),
        if (onStartVerification case final onStartVerification?)
          LinagoraSettingItem(
            leadingIcon: Icons.verified_user,
            title: l10n.startVerification,
            subtitle: l10n.syncDeviceWithCurrentSession,
            showDivider: true,
            crossAxisAlignment: CrossAxisAlignment.start,
            onTap: () => _runAfterClose(context, onStartVerification),
          ),
        if (onRemove case final onRemove?)
          LinagoraSettingItem(
            leadingIcon: Icons.delete_outline,
            title: l10n.removeDevice,
            subtitle: l10n.signOutAndRemoveSession,
            titleColor: colors.error,
            subtitleColor: colors.error,
            showDivider: true,
            crossAxisAlignment: CrossAxisAlignment.start,
            onTap: () => _runAfterClose(context, onRemove),
          ),
        const SizedBox(height: _gapActionsToCancel),
        Align(
          alignment: Alignment.center,
          child: LinagoraButton(
            label: l10n.cancel,
            variant: LinagoraButtonVariant.outlined,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

class _HeaderDivider extends StatelessWidget {
  const _HeaderDivider();

  @override
  Widget build(BuildContext context) {
    final dividerStyle = LinagoraDividerStyle.material();
    return Divider(
      height: dividerStyle.thickness,
      thickness: dividerStyle.thickness,
      color: dividerStyle.color,
    );
  }
}
