import 'package:flutter/material.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_context_menu_actions.dart';
import 'package:twake_chat/widgets/mixins/popup_menu_widget_mixin.dart';

class SettingsProfileContextMenuItem extends StatelessWidget
    with PopupMenuWidgetMixin {
  final SettingsProfileContextMenuActions action;
  final Listenable profileListenable;
  final bool Function() hasAvatar;
  final VoidCallback onTap;

  const SettingsProfileContextMenuItem({
    super.key,
    required this.action,
    required this.profileListenable,
    required this.hasAvatar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The menu children are built once, before the profile loads.
    return ListenableBuilder(
      listenable: profileListenable,
      builder: (context, _) => popupItemByTwakeAppRouter(
        context,
        action.getTitle(context, hasAvatar: hasAvatar()),
        iconAction: action.getIcon(),
        isClearCurrentPage: false,
        onCallbackAction: onTap,
      ),
    );
  }
}
