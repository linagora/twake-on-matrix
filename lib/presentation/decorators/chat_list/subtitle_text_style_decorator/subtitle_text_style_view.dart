import 'package:fluffychat/presentation/decorators/chat_list/subtitle_text_style_decorator/subtitle_text_style_decorator.dart';

class ChatListSubSubtitleTextStyleView {
  static ChatListSubtitleTextStyle textStyle = ChatListSubtitleTextStyle(
    MuteChatListSubtitleTextStyleDecorator(
      UnreadChatListSubtitleTextStyleDecorator(
        ReadChatListSubtitleTextStyleDecorator(),
      ),
    ),
  );
}
