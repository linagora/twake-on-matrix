import 'package:fluffychat/pages/settings_dashboard/settings/settings_view_style.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class SettingsItemBuilder extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData leading;
  final VoidCallback onTap;
  final bool isHideTrailingIcon;
  final bool isSelected;

  const SettingsItemBuilder({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.onTap,
    this.isHideTrailingIcon = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return TwakeInkWell(
      isSelected: isSelected,
      onTap: onTap,
      child: Padding(
        padding: SettingsViewStyle.itemBuilderPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: SettingsViewStyle.leadingItemBuilderPadding,
              child: Icon(
                leading,
                size: SettingsViewStyle.iconSize,
                color: isHideTrailingIcon
                    ? Theme.of(context).colorScheme.error
                    : LinagoraRefColors.material().tertiary[30],
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: subtitle.isEmpty
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: ListItemStyle.titleTextStyle(
                            fontFamily:
                                GoogleFonts.inter().fontFamily ?? 'Inter',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Padding(
                          padding: SettingsViewStyle.subtitleItemBuilderPadding,
                          child: Text(
                            subtitle,
                            style: ListItemStyle.subtitleTextStyle(
                              fontFamily:
                                  GoogleFonts.inter().fontFamily ?? 'Inter',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
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
    );
  }
}
