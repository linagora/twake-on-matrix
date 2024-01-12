import 'package:fluffychat/pages/chat_details/chat_details.dart';
import 'package:fluffychat/pages/chat_details/chat_details_edit.dart';
import 'package:fluffychat/utils/platform_infos.dart';

import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:flutter/material.dart';

class ChatDetailsRoutes {
  static const String chatDetails = '/groupChatDetails';
  static const String chatDetailsEdit = '/groupChatDetails/edit';
}

class ChatDetailsNavigator extends StatelessWidget {
  final VoidCallback? onBack;
  final String? roomId;
  final PresentationContact? contact;
  final bool isInStack;

  const ChatDetailsNavigator({
    Key? key,
    this.onBack,
    this.roomId,
    this.contact,
    required this.isInStack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformInfos.isMobile) {
      return ChatDetails(
        roomId: roomId!,
        onBack: onBack,
        isInStack: isInStack,
      );
    }
    return Navigator(
      initialRoute: ChatDetailsRoutes.chatDetails,
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (context) {
          switch (settings.name) {
            case ChatDetailsRoutes.chatDetails:
              return ChatDetails(
                roomId: roomId!,
                onBack: onBack,
                isInStack: isInStack,
              );
            case ChatDetailsRoutes.chatDetailsEdit:
              return ChatDetailsEdit(
                roomId: roomId!,
              );
            default:
              return const SizedBox();
          }
        },
      ),
    );
  }
}
