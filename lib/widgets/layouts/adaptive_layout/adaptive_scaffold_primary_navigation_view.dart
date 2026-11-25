import 'package:twake_chat/pages/chat_list/client_chooser_button_style.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';
import 'package:twake_chat/widgets/layouts/adaptive_layout/adaptive_scaffold_primary_navigation_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

class AdaptiveScaffoldPrimaryNavigationView extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(activeMatrixClientProvider);
    if (client == null) return const SizedBox.shrink();
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        width: AdaptiveScaffoldPrimaryNavigationStyle.primaryNavigationWidth,
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
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
                    AdaptiveScaffoldPrimaryNavigationStyle.selectedLabelTextStyle(
                      context,
                    ),
                unselectedLabelTextStyle:
                    AdaptiveScaffoldPrimaryNavigationStyle.labelTextStyle(
                      context,
                    ),
                indicatorColor: LinagoraSysColors.material().secondaryContainer,
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
                Padding(
                  padding: AdaptiveScaffoldPrimaryNavigationStyle.avatarPadding,
                  child: ValueListenableBuilder(
                    valueListenable: profileNotifier,
                    builder: (context, profile, _) {
                      return Avatar(
                        mxContent: profile.avatarUrl,
                        name: profile.displayName ?? client.userID!.localpart,
                        size: AdaptiveScaffoldPrimaryNavigationStyle.avatarSize,
                        fontSize:
                            ClientChooserButtonStyle.avatarFontSizeInAppBar,
                        onTap: () => const ProfileRoute().go(context),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
