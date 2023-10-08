import 'package:fluffychat/presentation/decorators/chat_list/title_text_style_decorator/title_text_style_decorator.dart';

class ChatLitTitleTextStyleView {
  static ChatListTitleTextStyle textStyle = ChatListTitleTextStyle(
    MuteChatListTitleTextStyleDecorator(
      UnreadChatListTitleTextStyleDecorator(
        ReadChatListTitleTextStyleDecorator(),
      ),
    ),
  );
}
