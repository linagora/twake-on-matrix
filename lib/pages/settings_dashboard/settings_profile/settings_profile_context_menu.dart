import 'package:flutter/material.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_context_menu_actions.dart';
import 'package:twake_chat/widgets/mixins/popup_menu_widget_mixin.dart';
import 'package:twake_chat/widgets/mixins/popup_menu_widget_style.dart';

class SettingsProfileContextMenu extends StatelessWidget
    with PopupMenuWidgetMixin {
  final bool hasAvatar;
  final ValueChanged<SettingsProfileContextMenuActions> onAction;

  const SettingsProfileContextMenu({
    super.key,
    required this.hasAvatar,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      SettingsProfileContextMenuActions.edit,
      if (hasAvatar) SettingsProfileContextMenuActions.delete,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final action in actions) ...[
          if (action != actions.first)
            Divider(
              height: PopupMenuWidgetStyle.dividerHeight,
              thickness: PopupMenuWidgetStyle.dividerThickness,
              color: PopupMenuWidgetStyle.defaultDividerColor(context),
            ),
          popupItemByTwakeAppRouter(
            context,
            action.getTitle(context, hasAvatar: hasAvatar),
            iconAction: action.getIcon(),
            isClearCurrentPage: false,
            onCallbackAction: () => onAction(action),
          ),
        ],
      ],
    );
  }
}
