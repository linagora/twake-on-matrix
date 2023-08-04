import 'package:fluffychat/domain/model/search/recent_chat_model.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/client_stories_extension.dart';
import 'package:matrix/matrix.dart';

extension RoomExtension on Room {
  RecentChatSearchModel toRecentChatSearchModel(MatrixLocalizations matrixLocalizations) {
    return RecentChatSearchModel(
      id,
      displayName: getLocalizedDisplayname(matrixLocalizations),
      roomSummary: summary,
    );
  }

  bool isNotSpaceAndStoryRoom() {
    return !isSpace && !isStoryRoom;
  }

  bool isShowInChatList() {
    return _isDirectChatHaveMessage() || _isGroupChat();
  }

  bool _isGroupChat() {
    return !isDirectChat;
  }

  bool _isDirectChatHaveMessage() {
    return isDirectChat && _isLastEventInRoomIsMessage();
  }

  bool _isLastEventInRoomIsMessage() {
    return [
      EventTypes.Message,
      EventTypes.Sticker,
      EventTypes.Encrypted,
    ].contains(lastEvent?.type);
  }
}