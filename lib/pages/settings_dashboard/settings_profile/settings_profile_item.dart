import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_item_style.dart';
import 'package:fluffychat/presentation/enum/settings/settings_profile_enum.dart';
import 'package:fluffychat/presentation/model/settings/settings_profile_presentation.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class SettingsProfileItemBuilder extends StatelessWidget {
  final String title;
  final SettingsProfilePresentation settingsProfilePresentation;
  final SettingsProfileEnum settingsProfileEnum;
  final TextEditingController? textEditingController;
  final IconData suffixIcon;
  final IconData? leadingIcon;
  final VoidCallback? onCopyAction;
  final bool canEditDisplayName;
  final bool enableDivider;
  final VoidCallback? onEditRequested;

  const SettingsProfileItemBuilder({
    super.key,
    required this.settingsProfileEnum,
    required this.title,
    required this.settingsProfilePresentation,
    this.textEditingController,
    required this.suffixIcon,
    this.leadingIcon,
    this.onCopyAction,
    required this.canEditDisplayName,
    this.enableDivider = true,
    this.onEditRequested,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            if (leadingIcon != null)
              Padding(
                padding: SettingsProfileItemStyle.itemBuilderPadding,
                child: Icon(
                  leadingIcon,
                  size: SettingsProfileItemStyle.iconSize,
                  color: LinagoraSysColors.material().tertiary,
                ),
              ),
            Expanded(
              child: Padding(
                padding: SettingsProfileItemStyle.textPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: LinagoraRefColors.material().neutral[40],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (textEditingController != null)
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: textEditingController!,
                        builder: (context, value, _) {
                          return Text(
                            value.text,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: LinagoraSysColors.material().onSurface,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (hasSuffixIcon)
              IconButton(
                onPressed: settingsProfilePresentation.isEditable
                    ? onEditRequested ?? () {}
                    : onCopyAction,
                icon: Icon(
                  suffixIcon,
                  size: SettingsProfileItemStyle.copyIconSize,
                  color: LinagoraRefColors.material().tertiary[40],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (enableDivider)
          Container(
            width: double.infinity,
            height: 1,
            margin: const EdgeInsets.only(left: 40),
            color: LinagoraStateLayer(
              LinagoraSysColors.material().surfaceTint,
            ).opacityLayer3,
          ),
      ],
    );
  }

  bool get hasSuffixIcon {
    return switch (settingsProfileEnum) {
      SettingsProfileEnum.displayName => canEditDisplayName,
      _ => true,
    };
  }
}
