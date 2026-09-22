import 'package:flutter/material.dart';

import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/bootstrap/bootstrap_modal_chrome.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';

class ChangeDeviceNameDialog {
  const ChangeDeviceNameDialog._();

  static Future<void> show(
    BuildContext context, {
    required String initialName,
    required Future<void> Function(String name) onSave,
  }) {
    return TwakeDialog.showDialogFullScreen(
      useSafeArea: false,
      builder: () => Builder(
        builder: (dialogContext) => BootstrapModalChrome(
          onClose: () => Navigator.of(dialogContext).pop(),
          forceCenteredDialog: true,
          content: ChangeDeviceNameView(
            initialName: initialName,
            onSave: onSave,
          ),
        ),
      ),
    );
  }
}

class ChangeDeviceNameView extends StatefulWidget {
  final String initialName;
  final Future<void> Function(String name) onSave;

  const ChangeDeviceNameView({
    super.key,
    required this.initialName,
    required this.onSave,
  });

  @override
  State<ChangeDeviceNameView> createState() => _ChangeDeviceNameViewState();
}

class _ChangeDeviceNameViewState extends State<ChangeDeviceNameView> {
  static const double _iconSize = 44;
  static const double _gapHeadingToField = 24;
  static const double _gapFieldToButton = LinagoraSpacing.base * 2;

  late final _controller = TextEditingController(text: widget.initialName);
  bool _isSaving = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final name = _controller.text.trim();
    if (name.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      await widget.onSave(name);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = L10n.of(context)!.couldNotSaveChangesTryLater;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final sysColors = LinagoraSysColors.material();
    final refColors = LinagoraRefColors.material();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: _iconSize,
          child: Icon(
            Icons.devices,
            size: _iconSize,
            color: refColors.tertiary[30],
          ),
        ),
        Text(
          l10n.changeDeviceName,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: sysColors.onSurface),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: LinagoraSpacing.base),
          child: Text(
            l10n.enterNewDisplayName,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: sysColors.textSecondary),
          ),
        ),
        const SizedBox(height: _gapHeadingToField),
        LinagoraTextField(
          controller: _controller,
          label: l10n.changeDeviceName,
          errorText: _errorText,
          enabled: !_isSaving,
          autofocus: true,
          textInputAction: TextInputAction.done,
          inputStyle: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: sysColors.onSurface),
          hintStyle: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: refColors.tertiary[30]),
          onChanged: (_) {
            if (_errorText != null) setState(() => _errorText = null);
          },
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: _gapFieldToButton),
        Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: _isSaving ? 0 : 1,
              child: LinagoraButton(
                label: l10n.save,
                onPressed: _isSaving ? null : _save,
              ),
            ),
            if (_isSaving)
              SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: sysColors.primary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
