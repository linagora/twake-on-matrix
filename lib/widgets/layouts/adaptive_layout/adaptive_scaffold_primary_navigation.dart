import 'dart:async';

import 'package:fluffychat/event/twake_inapp_event_types.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_primary_navigation_view.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class AdaptiveScaffoldPrimaryNavigation extends StatefulWidget {
  final List<NavigationRailDestination> getNavigationRailDestinations;
  final int? selectedIndex;
  final Function(int)? onDestinationSelected;

  const AdaptiveScaffoldPrimaryNavigation({
    super.key,
    required this.getNavigationRailDestinations,
    this.selectedIndex,
    this.onDestinationSelected,
  });

  @override
  State<AdaptiveScaffoldPrimaryNavigation> createState() =>
      _AdaptiveScaffoldPrimaryNavigationState();
}

class _AdaptiveScaffoldPrimaryNavigationState
    extends State<AdaptiveScaffoldPrimaryNavigation> {
  final ValueNotifier<Profile> profileNotifier = ValueNotifier(
    Profile(userId: ''),
  );

  StreamSubscription? onAccountDataSubscription;

  Client get client => Matrix.of(context).client;

  void _getCurrentProfile(Client client) async {
    final profile = await client.getProfileFromUserId(
      client.userID!,
      getFromRooms: false,
    );
    Logs().d(
      'AdaptiveScaffoldPrimaryNavigation::_getCurrentProfile() - currentProfile: $profile',
    );
    profileNotifier.value = profile;
  }

  void _handleOnAccountDataSubscription() {
    onAccountDataSubscription = client.onAccountData.stream.listen((event) {
      if (event.type == TwakeInappEventTypes.uploadAvatarEvent) {
        final newProfile = Profile.fromJson(event.content);
        if (newProfile.avatarUrl != profileNotifier.value.avatarUrl) {
          profileNotifier.value = Profile.fromJson(event.content);
        }
      }
    });
  }

  @override
  void initState() {
    _getCurrentProfile(client);
    _handleOnAccountDataSubscription();
    super.initState();
  }

  @override
  void dispose() {
    onAccountDataSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffoldPrimaryNavigationView(
      getNavigationRailDestinations: widget.getNavigationRailDestinations,
      selectedIndex: widget.selectedIndex,
      onDestinationSelected: widget.onDestinationSelected,
      profileNotifier: profileNotifier,
    );
  }
}
