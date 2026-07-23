import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_option.dart';
import 'package:fluffychat/pages/bootstrap/verify_device_view_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
        const SizedBox(height: VerifyDeviceViewStyle.gapMascotToHeading),
        Padding(
          padding: VerifyDeviceViewStyle.headingPadding,
          child: Text(
            L10n.of(context)!.verifyThisDevice,
            textAlign: TextAlign.center,
            style: VerifyDeviceViewStyle.titleStyle(context),
          ),
        ),
        const SizedBox(height: VerifyDeviceViewStyle.gapTitleToSupporting),
        Text(
          L10n.of(context)!.verifyThisDeviceDescription,
          textAlign: TextAlign.center,
          style: VerifyDeviceViewStyle.supportingStyle(context),
        ),
        const SizedBox(height: VerifyDeviceViewStyle.gapHeadingToOptions),
        for (int index = 0; index < options.length; index++)
          _VerifyDeviceItem(
            option: options[index],
            showDivider: index != options.length - 1,
            disabled: isBusy,
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

class _VerifyDeviceItem extends StatelessWidget {
  final VerifyDeviceOption option;
  final bool showDivider;
  final bool disabled;

  const _VerifyDeviceItem({
    required this.option,
    required this.showDivider,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : option.onTap,
      child: IntrinsicHeight(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: VerifyDeviceViewStyle.settingItemHeight,
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: VerifyDeviceViewStyle.settingItemPadding,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        option.icon,
                        size: VerifyDeviceViewStyle.settingIconSize,
                        color: VerifyDeviceViewStyle.iconColor(context),
                      ),
                      const SizedBox(width: VerifyDeviceViewStyle.settingGap),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              option.title,
                              style: VerifyDeviceViewStyle.settingTitleStyle(
                                context,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(
                              height: VerifyDeviceViewStyle.settingTextGap,
                            ),
                            Text(
                              option.subtitle,
                              style: VerifyDeviceViewStyle.settingSubtitleStyle(
                                context,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: VerifyDeviceViewStyle.settingGap),
                      if (option.isLoading)
                        SizedBox(
                          width: VerifyDeviceViewStyle.settingIconSize,
                          height: VerifyDeviceViewStyle.settingIconSize,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: VerifyDeviceViewStyle.iconColor(context),
                          ),
                        )
                      else
                        Icon(
                          Icons.chevron_right,
                          size: VerifyDeviceViewStyle.settingIconSize,
                          color: VerifyDeviceViewStyle.iconColor(context),
                        ),
                    ],
                  ),
                ),
              ),
              if (showDivider)
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: VerifyDeviceViewStyle.dividerIndent,
                  endIndent: 0,
                  color: VerifyDeviceViewStyle.dividerColor,
                ),
            ],
          ),
        ),
      ),
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
