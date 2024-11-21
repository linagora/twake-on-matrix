import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat_adaptive_scaffold/chat_adaptive_scaffold_builder.dart';
import 'package:fluffychat/pages/chat_details/chat_details_navigator.dart';
import 'package:fluffychat/pages/chat_search/chat_search.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_navigator.dart';
import 'package:fluffychat/presentation/enum/chat/right_column_type_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:matrix/matrix.dart';

class ChatAdaptiveScaffold extends StatefulWidget {
  final String roomId;
  final List<MatrixFile?>? shareFiles;
  final String? roomName;

  const ChatAdaptiveScaffold({
    super.key,
    required this.roomId,
    this.shareFiles,
    this.roomName,
  });

  @override
  State<ChatAdaptiveScaffold> createState() => ChatAdaptiveScaffoldController();
}

class ChatAdaptiveScaffoldController extends State<ChatAdaptiveScaffold> {
  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: ChatAdaptiveScaffoldBuilder(
        bodyBuilder: (controller) => Chat(
          roomId: widget.roomId,
          shareFiles: widget.shareFiles,
          roomName: widget.roomName,
          onChangeRightColumnType: controller.setRightColumnType,
        ),
        rightBuilder: (
          controller, {
          required bool isInStack,
          required RightColumnType type,
        }) {
          return _RightColumnNavigator(
            isInStack: isInStack,
            controller: controller,
            type: type,
            roomId: widget.roomId,
          );
        },
      ),
    );
  }
}

class _RightColumnNavigator extends StatelessWidget {
  final ChatAdaptiveScaffoldBuilderController controller;
  final bool isInStack;
  final RightColumnType type;
  final String roomId;

  const _RightColumnNavigator({
    required this.controller,
    required this.isInStack,
    required this.type,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case RightColumnType.search:
        return ChatSearch(
          roomId: roomId,
          onBack: controller.hideRightColumn,
          isInStack: isInStack,
        );
      case RightColumnType.profileInfo:
        return ChatProfileInfoNavigator(
          onBack: controller.hideRightColumn,
          roomId: roomId,
          isInStack: isInStack,
        );
      case RightColumnType.groupChatDetails:
        return ChatDetailsNavigator(
          closeRightColumn: controller.hideRightColumn,
          roomId: roomId,
          isInStack: isInStack,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
