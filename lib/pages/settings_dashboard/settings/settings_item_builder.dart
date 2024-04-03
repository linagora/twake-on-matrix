import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/settings_dashboard/settings/settings_view_style.dart';
import 'package:flutter/material.dart';
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
    return Material(
      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      clipBehavior: Clip.hardEdge,
      color: isSelected
          ? Theme.of(context).colorScheme.secondaryContainer
          : LinagoraSysColors.material().onPrimary,
      child: InkWell(
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
                      : Theme.of(context).colorScheme.onSurfaceVariant,
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: isHideTrailingIcon
                                      ? Theme.of(context).colorScheme.error
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Padding(
                            padding:
                                SettingsViewStyle.subtitleItemBuilderPadding,
                            child: Text(
                              subtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: LinagoraRefColors.material()
                                        .neutral[40],
                                  ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isHideTrailingIcon)
                      const Icon(
                        Icons.chevron_right_outlined,
                        size: SettingsViewStyle.iconSize,
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
