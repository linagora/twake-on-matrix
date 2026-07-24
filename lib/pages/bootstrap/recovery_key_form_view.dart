import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_view_style.dart';
import 'package:fluffychat/pages/key_verification/key_verification_sas_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

/// Recovery-key entry step of [VerifyDeviceScreen].
///
/// The web-modal close (X) button lives in the shared modal chrome
/// ([VerifyDeviceScreen]'s `_WebVerifyDeviceModal`), not here — this view
/// only renders the key icon, heading, field and submit button.
class RecoveryKeyFormView extends StatefulWidget {
  final Future<bool> Function(String recoveryKey) onVerify;
  final String? initialValue;
  final String? initialErrorText;

  const RecoveryKeyFormView({
    super.key,
    required this.onVerify,
    this.initialValue,
    this.initialErrorText,
  });

  @override
  State<RecoveryKeyFormView> createState() => _RecoveryKeyFormViewState();
}

class _RecoveryKeyFormViewState extends State<RecoveryKeyFormView> {
  static const double _gapHeadingToField = 24;
  static const double _gapFieldToButton = 19;
  static const double _buttonWidth = 88;
  static const double _buttonHeight = 48;

  late final _controller = TextEditingController(text: widget.initialValue);
  late String? _errorText = widget.initialErrorText;
  bool _isVerifying = false;
  bool _obscureText = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isVerifying) return;
    final recoveryKey = _controller.text;
    if (recoveryKey.isEmpty) {
      setState(() => _errorText = L10n.of(context)!.recoveryKeyRequired);
      return;
    }
    setState(() {
      _isVerifying = true;
      _errorText = null;
    });
    final success = await widget.onVerify(recoveryKey);
    if (!mounted) return;
    if (!success) {
      setState(() {
        _isVerifying = false;
        _errorText = L10n.of(context)!.recoveryKeyDoesntMatch;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            Icons.key_off_outlined,
            size: VerifyDeviceViewStyle.settingIconSize,
            color: VerifyDeviceViewStyle.subtitleColor,
          ),
        ),
        Padding(
          padding: VerifyDeviceViewStyle.headingPadding,
          child: Text(
            L10n.of(context)!.enterRecoveryKey,
            textAlign: TextAlign.center,
            style: VerifyDeviceViewStyle.titleStyle(context),
          ),
        ),
        const SizedBox(height: VerifyDeviceViewStyle.gapTitleToSupporting),
        Text(
          L10n.of(context)!.enterRecoveryKeyDescription,
          textAlign: TextAlign.center,
          style: VerifyDeviceViewStyle.supportingStyle(context),
        ),
        const SizedBox(height: _gapHeadingToField),
        LinagoraTextField(
          controller: _controller,
          label: L10n.of(context)!.recoveryKey,
          hintText: 'xxxx xxxx xxxx xxxx',
          labelStyle: KeyVerificationSasStyle.recoveryKeyLabelStyle(context),
          errorText: _errorText,
          obscureText: _obscureText,
          enabled: !_isVerifying,
          trailingIcon: _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          onTrailingIconPressed: () =>
              setState(() => _obscureText = !_obscureText),
          onChanged: (_) {
            if (_errorText != null) setState(() => _errorText = null);
          },
        ),
        const SizedBox(height: _gapFieldToButton),
        Material(
          color: KeyVerificationSasStyle.primaryColor,
          borderRadius: BorderRadius.circular(
            KeyVerificationSasStyle.buttonRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _isVerifying ? null : _submit,
            child: SizedBox(
              width: _buttonWidth,
              height: _buttonHeight,
              child: Center(
                child: _isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        L10n.of(context)!.verify,
                        style: KeyVerificationSasStyle.filledButtonTextStyle(
                          context,
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
