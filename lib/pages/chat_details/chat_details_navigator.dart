import 'package:fluffychat/pages/chat_details/chat_details.dart';
import 'package:fluffychat/pages/chat_details/chat_details_edit.dart';
import 'package:fluffychat/utils/platform_infos.dart';

import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:flutter/material.dart';

class ChatDetailsRoutes {
  static const String chatDetails = '/groupChatDetails';
  static const String chatDetailsEdit = '/groupChatDetails/edit';
}

class ChatDetailsNavigator extends StatelessWidget {
  final VoidCallback? closeRightColumn;
  final String? roomId;
  final PresentationContact? contact;
  final bool isInStack;

  const ChatDetailsNavigator({
    super.key,
    this.closeRightColumn,
    this.roomId,
    this.contact,
    required this.isInStack,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformInfos.isMobile) {
      return ChatDetails(
        roomId: roomId!,
        closeRightColumn: closeRightColumn,
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
                closeRightColumn: closeRightColumn,
                isInStack: isInStack,
              );
            case ChatDetailsRoutes.chatDetailsEdit:
              return ChatDetailsEdit(
                roomId: roomId!,
              );
            default:
              return ChatDetails(
                roomId: roomId!,
                closeRightColumn: closeRightColumn,
                isInStack: isInStack,
              );
          }
        },
      ),
    );
  }
}
