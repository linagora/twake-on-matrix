import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_context_menu_actions.dart';
import 'package:twake_chat/widgets/mixins/popup_menu_widget_mixin.dart';

class SettingsProfileContextMenuItem extends StatelessWidget
    with PopupMenuWidgetMixin {
  final SettingsProfileContextMenuActions action;
  final ValueListenable<Profile?> currentProfile;
  final VoidCallback onTap;

  const SettingsProfileContextMenuItem({
    super.key,
    required this.action,
    required this.currentProfile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The menu children are built once, before the profile loads.
    return ValueListenableBuilder<Profile?>(
      valueListenable: currentProfile,
      builder: (context, profile, _) => popupItemByTwakeAppRouter(
        context,
        action.getTitle(context, hasAvatar: profile?.avatarUrl != null),
        iconAction: action.getIcon(),
        isClearCurrentPage: false,
        onCallbackAction: onTap,
      ),
    );
  }
}
