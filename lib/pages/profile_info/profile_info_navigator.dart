import 'package:flutter/material.dart';

import 'package:fluffychat/pages/profile_info/profile_info.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';

class ProfileInfoRoutes {
  static const String profileInfo = '/profileInfo';
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
      initialRoute: ProfileInfoRoutes.profileInfo,
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (context) {
          switch (settings.name) {
            case ProfileInfoRoutes.profileInfo:
              return ProfileInfo(
                onBack: onBack,
                isInStack: isInStack,
                roomId: roomId,
                contact: contact,
              );
            default:
              return const SizedBox();
          }
        },
      ),
    );
  }
}
