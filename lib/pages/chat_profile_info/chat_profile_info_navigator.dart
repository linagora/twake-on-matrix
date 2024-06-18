import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/cupertino.dart';

import 'package:fluffychat/pages/chat_profile_info/chat_profile_info.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';

class ChatProfileInfoRoutes {
  static const String profileInfo = '/profileInfo';
}

class ChatProfileInfoNavigator extends StatelessWidget {
  final VoidCallback? onBack;
  final String? roomId;
  final PresentationContact? contact;
  final bool isInStack;
  final bool isDraftInfo;

  const ChatProfileInfoNavigator({
    super.key,
    this.onBack,
    this.roomId,
    this.contact,
    required this.isInStack,
    this.isDraftInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformInfos.isMobile) {
      return ChatProfileInfo(
        onBack: onBack,
        isInStack: isInStack,
        roomId: roomId,
        contact: contact,
        isDraftInfo: isDraftInfo,
      );
    }
    return Navigator(
      initialRoute: ChatProfileInfoRoutes.profileInfo,
      onGenerateRoute: (route) => CupertinoPageRoute(
        builder: (context) {
          switch (route.name) {
            case ChatProfileInfoRoutes.profileInfo:
              return ChatProfileInfo(
                onBack: onBack,
                isInStack: isInStack,
                roomId: roomId,
                contact: contact,
                isDraftInfo: isDraftInfo,
              );

            default:
              return const SizedBox();
          }
        },
      ),
    );
  }
}
