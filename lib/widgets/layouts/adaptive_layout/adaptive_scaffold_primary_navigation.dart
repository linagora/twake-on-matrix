import 'package:fluffychat/pages/chat_list/client_chooser_button.dart';
import 'package:fluffychat/pages/chat_list/client_chooser_button_style.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_primary_navigation_style.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class AdaptiveScaffoldPrimaryNavigation extends StatelessWidget {
  final ValueNotifier<Profile> profileNotifier;
  final List<NavigationRailDestination> getNavigationRailDestinations;
  final int? selectedIndex;
  final Function(int)? onDestinationSelected;
  final Function(Object)? onSelected;

  const AdaptiveScaffoldPrimaryNavigation({
    super.key,
    required this.profileNotifier,
    required this.getNavigationRailDestinations,
    this.selectedIndex,
    this.onDestinationSelected,
    this.onSelected,
  });

  List<PopupMenuEntry<Object>> _bundleMenuItems(BuildContext context) {
    return <PopupMenuEntry<Object>>[
      PopupMenuItem(
        value: SettingsAction.archive,
        child: Row(
          children: [
            const Icon(Icons.archive_outlined),
            const SizedBox(width: 18),
            Text(L10n.of(context)!.archive),
          ],
        ),
      ),
      PopupMenuItem(
        value: SettingsAction.settings,
        child: Row(
          children: [
            const Icon(Icons.settings_outlined),
            const SizedBox(width: 18),
            Text(L10n.of(context)!.settings),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        margin: AdaptiveScaffoldPrimaryNavigationStyle.primaryNavigationMargin,
        width: AdaptiveScaffoldPrimaryNavigationStyle.primaryNavigationWidth,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: NavigationRail(
                selectedIndex: selectedIndex,
                destinations: getNavigationRailDestinations,
                onDestinationSelected: onDestinationSelected,
                labelType: NavigationRailLabelType.all,
                backgroundColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            Column(
              children: [
                const Padding(
                  padding:
                      AdaptiveScaffoldPrimaryNavigationStyle.dividerPadding,
                  child: Divider(
                    height: AdaptiveScaffoldPrimaryNavigationStyle.dividerSize,
                    color: AdaptiveScaffoldPrimaryNavigationStyle
                        .separatorLightColor,
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: profileNotifier,
                  builder: (context, profile, _) {
                    return PopupMenuButton<Object>(
                      padding: EdgeInsets.zero,
                      onSelected: onSelected,
                      itemBuilder: _bundleMenuItems,
                      child: Avatar(
                        mxContent: profile.avatarUrl,
                        name: profile.displayName ??
                            Matrix.of(context).client.userID!.localpart,
                        size: AdaptiveScaffoldPrimaryNavigationStyle.avatarSize,
                        fontSize:
                            ClientChooserButtonStyle.avatarFontSizeInAppBar,
                      ),
                    );
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
