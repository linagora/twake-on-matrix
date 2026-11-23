import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_folders/settings_folders_style.dart';

/// One line to tick, edge to edge like the other rows of the screen.
class FolderCheckRow extends StatelessWidget {
  const FolderCheckRow({
    super.key,
    required this.title,
    required this.isChecked,
    required this.onChanged,
    this.leading,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool isChecked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = LinagoraSysColors.material();
    final subtitle = this.subtitle;
    final leading = this.leading;
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!isChecked),
        child: Padding(
          padding: leading == null
              ? SettingsFoldersStyle.rowPadding
              : SettingsFoldersStyle.checkRowPadding,
          child: Row(
            spacing: SettingsFoldersStyle.rowGap,
            children: [
              ?leading,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: LinagoraTextStyle.material().bodyMedium.copyWith(
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: SettingsFoldersStyle.helpText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              SizedBox.square(
                dimension: SettingsFoldersStyle.checkboxSize,
                // The row takes the focus, so Tab stops once per row.
                child: ExcludeFocus(
                  child: Checkbox(
                    value: isChecked,
                    onChanged: (isOn) => onChanged(isOn ?? false),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
