import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_item_style.dart';
import 'package:fluffychat/presentation/enum/settings/settings_profile_enum.dart';
import 'package:fluffychat/presentation/model/settings/settings_profile_presentation.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class SettingsProfileItemBuilder extends StatelessWidget {
  final String title;
  final SettingsProfilePresentation settingsProfilePresentation;
  final SettingsProfileEnum settingsProfileEnum;
  final FocusNode? focusNode;
  final TextEditingController? textEditingController;
  final IconData suffixIcon;
  final IconData? leadingIcon;
  final void Function(String, SettingsProfileEnum)? onChange;
  final VoidCallback? onCopyAction;
  final ValueNotifier<Either<Failure, Success>> settingsProfileUIState;

  const SettingsProfileItemBuilder({
    super.key,
    required this.settingsProfileEnum,
    required this.title,
    required this.settingsProfilePresentation,
    this.focusNode,
    this.textEditingController,
    required this.suffixIcon,
    this.leadingIcon,
    this.onChange,
    this.onCopyAction,
    required this.settingsProfileUIState,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: SettingsProfileItemStyle.itemBuilderPadding,
          child: Icon(
            leadingIcon,
            size: SettingsProfileItemStyle.iconSize,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: LinagoraRefColors.material().neutral[40],
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    ValueListenableBuilder(
                      valueListenable: settingsProfileUIState,
                      builder: (context, _, __) {
                        return TextField(
                          onChanged: (value) =>
                              onChange!(value, settingsProfileEnum),
                          readOnly: !settingsProfilePresentation.isEditable,
                          autofocus: false,
                          focusNode: focusNode,
                          controller: textEditingController,
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              onPressed: settingsProfilePresentation.isEditable
                                  ? () {
                                      focusNode?.requestFocus();
                                    }
                                  : onCopyAction,
                              icon: Icon(
                                suffixIcon,
                                size: SettingsProfileItemStyle.iconSize,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            hintText: textEditingController?.text,
                          ),
                        );
                      },
                    ),
                    Divider(
                      height: SettingsProfileItemStyle.dividerSize,
                      color: LinagoraStateLayer(
                        LinagoraSysColors.material().surfaceTint,
                      ).opacityLayer3,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
