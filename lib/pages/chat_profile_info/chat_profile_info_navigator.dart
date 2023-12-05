import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_shared/chat_profile_info_shared.dart';
import 'package:flutter/material.dart';

import 'package:fluffychat/pages/chat_profile_info/chat_profile_info.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';

class ProfileInfoRoutes {
  static const String profileInfo = '/profileInfo';
  static const String profileInfoShared = 'profileInfo/shared';

  static final GlobalKey<NavigatorState> innerNavigatorProfileKey = GlobalKey(
    debugLabel: 'innerNavigatorProfileKey',
  );
}

class ProfileInfoNavigator extends StatelessWidget {
  final VoidCallback? onBack;
  final String? roomId;
  final PresentationContact? contact;
  final bool isInStack;

  const ProfileInfoNavigator({
    Key? key,
    this.onBack,
    this.roomId,
    this.contact,
    required this.isInStack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: ProfileInfoRoutes.innerNavigatorProfileKey,
      initialRoute: ProfileInfoRoutes.profileInfo,
      onGenerateRoute: (route) => MaterialPageRoute(
        builder: (context) {
          switch (route.name) {
            case ProfileInfoRoutes.profileInfo:
              return ProfileInfo(
                onBack: onBack,
                isInStack: isInStack,
                roomId: roomId,
                contact: contact,
              );

            case ProfileInfoRoutes.profileInfoShared:
              return ProfileInfoShared(
                roomId: route.arguments as String,
              );
            default:
              return const SizedBox();
          }
        },
      ),
    );
  }
}
