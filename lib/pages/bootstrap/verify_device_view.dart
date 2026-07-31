import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_option.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_view_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class VerifyDeviceView extends StatelessWidget {
  final double mascotWidth;
  final double mascotHeight;
  final VoidCallback? onRetry;
  final List<VerifyDeviceOption> options;

  const VerifyDeviceView({
    super.key,
    required this.mascotWidth,
    required this.mascotHeight,
    required this.options,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // Block the whole chooser while a row is loading, prevents double-tap.
    final isBusy = options.any((option) => option.isLoading);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          ImagePaths.mascotVerifyDevices,
          width: mascotWidth,
          height: mascotHeight,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: VerifyDeviceViewStyle.gapMascotToSpinner),
        Padding(
          padding: VerifyDeviceViewStyle.headingPadding,
          child: Text(
            L10n.of(context)!.verifyThisDevice,
            textAlign: TextAlign.center,
            style: VerifyDeviceViewStyle.titleStyle(context),
          ),
        ),
        const SizedBox(height: LinagoraSpacing.base),
        Text(
          L10n.of(context)!.verifyThisDeviceDescription,
          textAlign: TextAlign.center,
          style: VerifyDeviceViewStyle.supportingStyle(context),
        ),
        const SizedBox(height: LinagoraSpacing.base),
        for (int index = 0; index < options.length; index++)
          LinagoraSettingItem(
            title: options[index].title,
            subtitle: options[index].subtitle,
            leadingIcon: options[index].icon,
            onTap: options[index].onTap,
            loading: options[index].isLoading,
            showDivider: index == 0,
            enabled: !isBusy,
          ),
        const SizedBox(height: VerifyDeviceViewStyle.gapOptionsToButton),
        _RetryButton(
          width: VerifyDeviceViewStyle.buttonWidth,
          onTap: isBusy ? null : onRetry,
        ),
      ],
    );
  }
}

class _RetryButton extends StatelessWidget {
  final double? width;
  final VoidCallback? onTap;

  const _RetryButton({this.width, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VerifyDeviceViewStyle.buttonColor,
      borderRadius: BorderRadius.circular(VerifyDeviceViewStyle.buttonRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: VerifyDeviceViewStyle.buttonPadding,
          child: SizedBox(
            width: width,
            child: Center(
              child: Text(
                L10n.of(context)!.retryAutomatically,
                style: VerifyDeviceViewStyle.buttonTextStyle(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
