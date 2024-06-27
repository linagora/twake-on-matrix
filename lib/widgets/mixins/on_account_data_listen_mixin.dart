import 'dart:async';

import 'package:fluffychat/event/twake_inapp_event_types.dart';
import 'package:matrix/matrix.dart';

mixin OnProfileChangeMixin {
  StreamSubscription? onAccountDataSubscription;

  void listenOnProfileChangeStream({
    required Client client,
    Profile? currentProfile,
    void Function(Profile newProfile)? onProfileChanged,
  }) {
    onAccountDataSubscription = client.onAccountData.stream.listen((event) {
      if (event.type == TwakeInappEventTypes.uploadAvatarEvent) {
        final newProfile = Profile.fromJson(event.content);
        Logs().d(
          'TwakeHeader::_handleOnAccountDataSubscription() - newProfileAvatar: ${newProfile.avatarUrl}, newProfileDisplayName: ${newProfile.displayName}',
        );
        if (newProfile.avatarUrl != currentProfile?.avatarUrl ||
            newProfile.displayName != currentProfile?.displayName) {
          onProfileChanged?.call(newProfile);
        }
      }
    });
  }
}
