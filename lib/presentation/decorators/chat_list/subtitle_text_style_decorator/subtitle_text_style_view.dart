import 'package:fluffychat/presentation/decorators/chat_list/subtitle_text_style_decorator/subtitle_text_style_decorator.dart';

class ChatLitSubSubtitleTextStyleView {
  static final SubtitleReadTextStyleDecorator _subtitleReadTextStyleDecorator =
      SubtitleReadTextStyleDecorator();
  static final SubtitleUnreadTextStyleDecorator _unreadTextStyleDecorator =
      SubtitleUnreadTextStyleDecorator(_subtitleReadTextStyleDecorator);
  static final SubtitleMuteAndUnreadTextStyleDecorator
      _muteAndUnreadTextStyleDecorator =
      SubtitleMuteAndUnreadTextStyleDecorator(_unreadTextStyleDecorator);
  static final SubtitleMuteAndReadTextStyleDecorator
      _muteAndReadTextStyleDecorator =
      SubtitleMuteAndReadTextStyleDecorator(_muteAndUnreadTextStyleDecorator);

  static ChatListSubtitleTextStyle subtitleTextStyle =
      ChatListSubtitleTextStyle(_muteAndReadTextStyleDecorator);
}
