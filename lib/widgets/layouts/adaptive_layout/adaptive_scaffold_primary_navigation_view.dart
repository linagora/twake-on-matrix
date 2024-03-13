import 'package:fluffychat/pages/chat_list/client_chooser_button_style.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_primary_navigation_style.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

class AdaptiveScaffoldPrimaryNavigationView extends StatelessWidget {
  final List<NavigationRailDestination> getNavigationRailDestinations;
  final int? selectedIndex;
  final Function(int)? onDestinationSelected;
  final ValueNotifier<Profile> profileNotifier;

  const AdaptiveScaffoldPrimaryNavigationView({
    super.key,
    required this.getNavigationRailDestinations,
    this.selectedIndex,
    this.onDestinationSelected,
    required this.profileNotifier,
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
                selectedLabelTextStyle:
                    AdaptiveScaffoldPrimaryNavigationStyle.labelTextStyle(
                  context,
                ),
                unselectedLabelTextStyle:
                    AdaptiveScaffoldPrimaryNavigationStyle.labelTextStyle(
                  context,
                ),
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
                    return Avatar(
                      mxContent: profile.avatarUrl,
                      name: profile.displayName ??
                          Matrix.of(context).client.userID!.localpart,
                      size: AdaptiveScaffoldPrimaryNavigationStyle.avatarSize,
                      fontSize: ClientChooserButtonStyle.avatarFontSizeInAppBar,
                      onTap: () => context.go('/rooms/profile'),
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
