import 'package:fluffychat/pages/settings_dashboard/settings/settings_view_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class SettingsItemBuilder extends StatelessWidget {
  final String title;
  final Color? titleColor;
  final Color? trailingIconColor;
  final IconData leading;
  final VoidCallback onTap;
  final bool isHideTrailingIcon;
  final bool isSelected;

  const SettingsItemBuilder({
    super.key,
    required this.title,
    required this.leading,
    required this.onTap,
    this.isHideTrailingIcon = false,
    this.isSelected = false,
    this.trailingIconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return TwakeInkWell(
      isSelected: isSelected,
      onTap: onTap,
      child: SizedBox(
        height: SettingsViewStyle.settingsItemHeight,
        child: Padding(
          padding: SettingsViewStyle.itemBuilderPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: SettingsViewStyle.leadingItemBuilderPadding,
                child: Icon(
                  leading,
                  size: SettingsViewStyle.iconSize,
                  color: trailingIconColor,
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
                            style: LinagoraTextStyle.material()
                                .bodyMedium2
                                .copyWith(
                                  color: titleColor,
                                  fontFamily: 'Inter',
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (!isHideTrailingIcon)
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
