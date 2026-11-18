import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_folders/settings_folders_style.dart';

/// A colour to pick, or none when [color] is null.
class FolderColorSwatch extends StatelessWidget {
  const FolderColorSwatch({
    super.key,
    required this.tooltip,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String tooltip;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = LinagoraSysColors.material();
    final color = this.color;
    return Semantics(
      selected: isSelected,
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: InkResponse(
          onTap: onTap,
          radius: SettingsFoldersStyle.swatchTapSize / 2,
          child: SizedBox.square(
            dimension: SettingsFoldersStyle.swatchTapSize,
            child: Center(
              child: Container(
                width: SettingsFoldersStyle.swatchSize,
                height: SettingsFoldersStyle.swatchSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: isSelected || color == null
                      ? Border.all(
                          color: isSelected ? colors.primary : colors.outline,
                          width: isSelected
                              ? SettingsFoldersStyle.swatchRingWidth
                              : 1,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        )
                      : null,
                ),
                child: switch ((color, isSelected)) {
                  (_, true) => Icon(
                    Icons.check,
                    size: SettingsFoldersStyle.swatchIconSize,
                    color: color == null ? colors.primary : colors.onPrimary,
                  ),
                  (null, false) => Icon(
                    Icons.format_color_reset_outlined,
                    size: SettingsFoldersStyle.swatchIconSize,
                    color: colors.tertiary,
                  ),
                  _ => null,
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
