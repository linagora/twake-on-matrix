import 'package:fluffychat/event/twake_inapp_event_types.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin FetchProfileMixin {
  final ValueNotifier<Profile> profileNotifier = ValueNotifier(
    Profile(userId: ''),
  );

  void getCurrentProfile(
    Client client, {
    isUpdated = false,
  }) async {
    final profile = await client.getProfileFromUserId(
      client.userID!,
      cache: !isUpdated,
      getFromRooms: false,
    );
    Logs().d(
      'FetchProfileMixin::_getCurrentProfile() - currentProfile: $profile',
    );
    profileNotifier.value = profile;
  }

  void handleOnAccountData(Client client) {
    client.onAccountData.stream.listen((event) {
      Logs().d(
        'FetchProfileMixin::onAccountData() - EventType: ${event.type} - EventContent: ${event.content}',
      );
      if (event.type == TwakeInappEventTypes.uploadAvatarEvent) {
        profileNotifier.value = Profile.fromJson(event.content);
      }
    });
  }
}
