import 'package:fluffychat/pages/settings_dashboard/settings/settings_view_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class SettingsItemBuilder extends StatelessWidget {
  final String title;
  final Color? titleColor;
  final Color? leadingIconColor;
  final IconData? leading;
  final Widget? leadingWidget;
  final VoidCallback onTap;
  final bool isHideTrailingIcon;
  final bool isSelected;
  final String? subtitle;
  final TextStyle? subtitleStyle;
  final Color? subtitleColor;
  final Widget? trailingWidget;
  final double? height;

  const SettingsItemBuilder({
    super.key,
    required this.title,
    this.leading,
    required this.onTap,
    this.isHideTrailingIcon = false,
    this.isSelected = false,
    this.leadingIconColor,
    this.titleColor,
    this.subtitleStyle,
    this.leadingWidget,
    this.subtitle,
    this.subtitleColor,
    this.trailingWidget,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return TwakeInkWell(
      isSelected: isSelected,
      onTap: onTap,
      key: key,
      child: SizedBox(
        height: height ?? SettingsViewStyle.settingsItemHeight,
        child: Padding(
          padding: SettingsViewStyle.itemBuilderPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: SettingsViewStyle.leadingItemBuilderPadding,
                child:
                    leadingWidget ??
                    Icon(
                      leading,
                      size: SettingsViewStyle.iconSize,
                      color: leadingIconColor,
                    ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: LinagoraTextStyle.material().bodyMedium2
                                .copyWith(
                                  color: titleColor,
                                  fontFamily: 'Inter',
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                subtitle!,
                                style:
                                    subtitleStyle ??
                                    LinagoraTextStyle.material().bodyMedium
                                        .copyWith(
                                          color:
                                              subtitleColor ??
                                              LinagoraRefColors.material()
                                                  .tertiary[30],
                                          fontFamily: 'Inter',
                                        ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!isHideTrailingIcon)
                      trailingWidget ??
                          Icon(
                            Icons.chevron_right_outlined,
                            size: SettingsViewStyle.iconSize,
                            color: LinagoraRefColors.material().tertiary[30],
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
