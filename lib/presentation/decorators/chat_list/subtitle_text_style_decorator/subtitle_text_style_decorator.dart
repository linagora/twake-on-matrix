import 'package:fluffychat/presentation/decorators/chat_list/subtitle_text_style_decorator/subtitle_text_style_component.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

abstract class TextStyleDecorator
    implements InterfaceChatListSubtitleTextStyleComponent {
  final InterfaceChatListSubtitleTextStyleComponent interfaceTextStyleComponent;

  TextStyleDecorator(this.interfaceTextStyleComponent);
}

class ChatListSubtitleTextStyle implements TextStyleDecorator {
  final InterfaceChatListSubtitleTextStyleComponent
      _interfaceTextStyleComponent;

  ChatListSubtitleTextStyle(this._interfaceTextStyleComponent);

  @override
  TextStyle textStyle(Room room) {
    return _interfaceTextStyleComponent.textStyle(room);
  }

  @override
  InterfaceChatListSubtitleTextStyleComponent get interfaceTextStyleComponent =>
      _interfaceTextStyleComponent;
}

class SubtitleReadTextStyleDecorator
    implements InterfaceChatListSubtitleTextStyleComponent {
  @override
  TextStyle textStyle(Room room) {
    return LinagoraTextStyle.material().bodyMedium3.copyWith(
          color: LinagoraSysColors.material().onSurface,
        );
  }
}

class SubtitleUnreadTextStyleDecorator implements TextStyleDecorator {
  final InterfaceChatListSubtitleTextStyleComponent
      _interfaceTextStyleComponent;

  SubtitleUnreadTextStyleDecorator(this._interfaceTextStyleComponent);

  @override
  TextStyle textStyle(Room room) {
    final unread = room.isUnread || room.membership == Membership.invite;
    if (unread) {
      return _interfaceTextStyleComponent.textStyle(room).merge(
            LinagoraTextStyle.material().bodyMedium2.copyWith(
                  color: LinagoraSysColors.material().onSurface,
                ),
          );
    } else {
      return _interfaceTextStyleComponent.textStyle(room);
    }
  }

  @override
  InterfaceChatListSubtitleTextStyleComponent get interfaceTextStyleComponent =>
      _interfaceTextStyleComponent;
}

class SubtitleMuteAndUnreadTextStyleDecorator implements TextStyleDecorator {
  final InterfaceChatListSubtitleTextStyleComponent
      _interfaceTextStyleComponent;

  SubtitleMuteAndUnreadTextStyleDecorator(this._interfaceTextStyleComponent);

  @override
  TextStyle textStyle(Room room) {
    final isMuted = room.pushRuleState != PushRuleState.notify;
    final unread = room.isUnread || room.membership == Membership.invite;
    if (isMuted && unread) {
      return _interfaceTextStyleComponent.textStyle(room).merge(
            LinagoraTextStyle.material().bodyMedium2.copyWith(
                  color: LinagoraRefColors.material().tertiary[20],
                ),
          );
    } else {
      return _interfaceTextStyleComponent.textStyle(room);
    }
  }

  @override
  InterfaceChatListSubtitleTextStyleComponent get interfaceTextStyleComponent =>
      _interfaceTextStyleComponent;
}

class SubtitleMuteAndReadTextStyleDecorator implements TextStyleDecorator {
  final InterfaceChatListSubtitleTextStyleComponent
      _interfaceTextStyleComponent;

  SubtitleMuteAndReadTextStyleDecorator(this._interfaceTextStyleComponent);

  @override
  TextStyle textStyle(Room room) {
    final isMuted = room.pushRuleState != PushRuleState.notify;
    final unread = room.isUnread || room.membership == Membership.invite;
    if (isMuted && !unread) {
      return _interfaceTextStyleComponent.textStyle(room).merge(
            LinagoraTextStyle.material().bodyMedium3.copyWith(
                  color: LinagoraRefColors.material().tertiary[20],
                ),
          );
    } else {
      return _interfaceTextStyleComponent.textStyle(room);
    }
  }

  @override
  InterfaceChatListSubtitleTextStyleComponent get interfaceTextStyleComponent =>
      _interfaceTextStyleComponent;
}
