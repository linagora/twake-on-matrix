import 'package:fluffychat/presentation/decorators/chat_list/title_text_style_decorator/title_text_style_decorator.dart';

class ChatLitTitleTextStyleView {
  static final TitleReadTextStyleDecorator _titleReadTextStyleDecorator =
      TitleReadTextStyleDecorator();
  static final TitleUnreadTextStyleDecorator _unreadTextStyleDecorator =
      TitleUnreadTextStyleDecorator(_titleReadTextStyleDecorator);
  static final TitleMuteAndUnreadTextStyleDecorator
      _muteAndUnreadTextStyleDecorator =
      TitleMuteAndUnreadTextStyleDecorator(_unreadTextStyleDecorator);
  static final TitleMuteAndReadTextStyleDecorator
      _muteAndReadTextStyleDecorator =
      TitleMuteAndReadTextStyleDecorator(_muteAndUnreadTextStyleDecorator);

  static ChatListTitleTextStyle titleTextStyle =
      ChatListTitleTextStyle(_muteAndReadTextStyleDecorator);
}
