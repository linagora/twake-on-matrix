import 'package:fluffychat/presentation/decorators/chat_list/title_text_style_decorator/title_text_style_component.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

abstract class TextStyleDecorator
    implements InterfaceChatListTitleTextStyleComponent {
  final InterfaceChatListTitleTextStyleComponent interfaceTextStyleComponent;

  TextStyleDecorator(this.interfaceTextStyleComponent);
}

class ChatListTitleTextStyle implements TextStyleDecorator {
  final InterfaceChatListTitleTextStyleComponent _interfaceTextStyleComponent;

  ChatListTitleTextStyle(this._interfaceTextStyleComponent);

  @override
  TextStyle textStyle(Room room) {
    return _interfaceTextStyleComponent.textStyle(room);
  }

  @override
  InterfaceChatListTitleTextStyleComponent get interfaceTextStyleComponent =>
      _interfaceTextStyleComponent;
}

class TitleReadTextStyleDecorator
    implements InterfaceChatListTitleTextStyleComponent {
  @override
  TextStyle textStyle(Room room) {
    return LinagoraTextStyle.material().bodyLarge2.copyWith(
          color: LinagoraSysColors.material().onSurface,
        );
  }
}

class TitleUnreadTextStyleDecorator implements TextStyleDecorator {
  final InterfaceChatListTitleTextStyleComponent _interfaceTextStyleComponent;

  TitleUnreadTextStyleDecorator(this._interfaceTextStyleComponent);

  @override
  TextStyle textStyle(Room room) {
    final unread = room.isUnread || room.membership == Membership.invite;
    if (unread) {
      return _interfaceTextStyleComponent.textStyle(room).merge(
            LinagoraTextStyle.material().bodyLarge1.copyWith(
                  color: LinagoraSysColors.material().onSurface,
                ),
          );
    } else {
      return _interfaceTextStyleComponent.textStyle(room);
    }
  }

  @override
  InterfaceChatListTitleTextStyleComponent get interfaceTextStyleComponent =>
      _interfaceTextStyleComponent;
}

class TitleMuteAndUnreadTextStyleDecorator implements TextStyleDecorator {
  final InterfaceChatListTitleTextStyleComponent _interfaceTextStyleComponent;

  TitleMuteAndUnreadTextStyleDecorator(this._interfaceTextStyleComponent);

  @override
  TextStyle textStyle(Room room) {
    final isMuted = room.pushRuleState != PushRuleState.notify;
    final unread = room.isUnread || room.membership == Membership.invite;
    if (isMuted && unread) {
      return _interfaceTextStyleComponent.textStyle(room).merge(
            LinagoraTextStyle.material().bodyLarge1.copyWith(
                  color: LinagoraRefColors.material().tertiary[20],
                ),
          );
    } else {
      return _interfaceTextStyleComponent.textStyle(room);
    }
  }

  @override
  InterfaceChatListTitleTextStyleComponent get interfaceTextStyleComponent =>
      _interfaceTextStyleComponent;
}

class TitleMuteAndReadTextStyleDecorator implements TextStyleDecorator {
  final InterfaceChatListTitleTextStyleComponent _interfaceTextStyleComponent;

  TitleMuteAndReadTextStyleDecorator(this._interfaceTextStyleComponent);

  @override
  TextStyle textStyle(Room room) {
    final isMuted = room.pushRuleState != PushRuleState.notify;
    final unread = room.isUnread || room.membership == Membership.invite;
    if (isMuted && !unread) {
      return _interfaceTextStyleComponent.textStyle(room).merge(
            LinagoraTextStyle.material().bodyLarge2.copyWith(
                  color: LinagoraRefColors.material().tertiary[20],
                ),
          );
    } else {
      return _interfaceTextStyleComponent.textStyle(room);
    }
  }

  @override
  InterfaceChatListTitleTextStyleComponent get interfaceTextStyleComponent =>
      _interfaceTextStyleComponent;
}
