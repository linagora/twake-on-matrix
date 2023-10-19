import 'package:fluffychat/pages/chat_list/client_chooser_button_style.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_primary_navigation_style.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class AdaptiveScaffoldPrimaryNavigationView extends StatelessWidget {
  final List<NavigationRailDestination> getNavigationRailDestinations;
  final int? selectedIndex;
  final Function(int)? onDestinationSelected;
  final Function(Object)? onSelected;
  final ValueNotifier<Profile> profileNotifier;
  final List<PopupMenuEntry<Object>> Function(BuildContext) itemBuilder;

  const AdaptiveScaffoldPrimaryNavigationView({
    super.key,
    required this.getNavigationRailDestinations,
    this.selectedIndex,
    this.onDestinationSelected,
    this.onSelected,
    required this.profileNotifier,
    required this.itemBuilder,
  });

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
                      itemBuilder: itemBuilder,
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
            ),
          ],
        ),
      ),
    );
  }
}
