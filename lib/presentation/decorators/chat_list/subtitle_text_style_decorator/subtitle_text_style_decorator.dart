import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/presentation/decorators/chat_list/subtitle_text_style_decorator/subtitle_text_style_component.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

abstract class ChatListSubtitleTextStyleDecorator
    implements ChatListSubtitleTextStyleComponent {
  final ChatListSubtitleTextStyleComponent interfaceTextStyleComponent;

  ChatListSubtitleTextStyleDecorator(this.interfaceTextStyleComponent);
}

class ChatListSubtitleTextStyle implements ChatListSubtitleTextStyleDecorator {
  final ChatListSubtitleTextStyleComponent _interfaceTextStyleComponent;

  ChatListSubtitleTextStyle(this._interfaceTextStyleComponent);

  @override
  TextStyle textStyle(Room room, BuildContext context) {
    return _interfaceTextStyleComponent.textStyle(room, context);
  }

  @override
  ChatListSubtitleTextStyleComponent get interfaceTextStyleComponent =>
      _interfaceTextStyleComponent;
}

class ReadChatListSubtitleTextStyleDecorator
    implements ChatListSubtitleTextStyleComponent {
  @override
  TextStyle textStyle(Room room, BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: LinagoraSysColors.material().onSurface,
          fontFamily: 'Inter',
        );
  }
}

class UnreadChatListSubtitleTextStyleDecorator
    implements ChatListSubtitleTextStyleDecorator {
  final ChatListSubtitleTextStyleComponent _interfaceTextStyleComponent;

  UnreadChatListSubtitleTextStyleDecorator(this._interfaceTextStyleComponent);

  @override
  TextStyle textStyle(Room room, BuildContext context) {
    if (room.isUnreadOrInvited) {
      return _interfaceTextStyleComponent.textStyle(room, context).merge(
            Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: LinagoraSysColors.material().onSurface,
                ),
          );
    } else {
      return _interfaceTextStyleComponent.textStyle(room, context);
    }
  }

  @override
  ChatListSubtitleTextStyleComponent get interfaceTextStyleComponent =>
      _interfaceTextStyleComponent;
}

class MuteChatListSubtitleTextStyleDecorator
    implements ChatListSubtitleTextStyleDecorator {
  final ChatListSubtitleTextStyleComponent _interfaceTextStyleComponent;

  MuteChatListSubtitleTextStyleDecorator(this._interfaceTextStyleComponent);

  @override
  TextStyle textStyle(Room room, BuildContext context) {
    if (room.isMuted) {
      return _interfaceTextStyleComponent.textStyle(room, context).copyWith(
            color: LinagoraSysColors.material().onSurface,
          );
    } else {
      return _interfaceTextStyleComponent.textStyle(room, context);
    }
  }

  @override
  ChatListSubtitleTextStyleComponent get interfaceTextStyleComponent =>
      _interfaceTextStyleComponent;
}
