import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat_adaptive_scaffold/chat_adaptive_scaffold_builder.dart';
import 'package:fluffychat/pages/chat_search/chat_search.dart';
import 'package:fluffychat/pages/profile_info/profile_info_navigator.dart';
import 'package:fluffychat/presentation/enum/chat/right_column_type_enum.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ChatAdaptiveScaffold extends StatefulWidget {
  final String roomId;
  final MatrixFile? shareFile;
  final String? roomName;

  const ChatAdaptiveScaffold({
    Key? key,
    required this.roomId,
    this.shareFile,
    this.roomName,
  }) : super(key: key);

  @override
  State<ChatAdaptiveScaffold> createState() => ChatAdaptiveScaffoldController();
}

class ChatAdaptiveScaffoldController extends State<ChatAdaptiveScaffold> {
  @override
  Widget build(BuildContext context) {
    return ChatAdaptiveScaffoldBuilder(
      bodyBuilder: (controller) => Chat(
        roomId: widget.roomId,
        shareFile: widget.shareFile,
        roomName: widget.roomName,
        onChangeRightColumnType: controller.setRightColumnType,
        jumpToEventIdStream: controller.jumpToEventIdStream,
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
          jumpToEventId: controller.jumpToEventId,
          isInStack: isInStack,
        );
      case RightColumnType.profileInfo:
        return ProfileInfoNavigator(
          onBack: controller.hideRightColumn,
          roomId: roomId,
          isInStack: isInStack,
        );
    }
  }
}
