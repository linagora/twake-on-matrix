import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/domain/model/search/recent_chat_model.dart';
import 'package:matrix/matrix.dart';

extension RoomListExtension on List<Room> {
  bool _matchedMatrixId(RecentChatSearchModel model, String keyword) {
    return model.directChatMatrixID?.toLowerCase().contains(
          keyword.toLowerCase(),
        ) ??
        false;
  }

  bool _matchedName(RecentChatSearchModel model, String keyword) {
    return model.displayName?.toLowerCase().contains(keyword.toLowerCase()) ??
        false;
  }

  bool _matchedNameOrMatrixId(RecentChatSearchModel model, String keyword) {
    return _matchedName(model, keyword) || _matchedMatrixId(model, keyword);
  }

  List<RecentChatSearchModel> searchRecentChat({
    required MatrixLocalizations matrixLocalizations,
    required String keyword,
    int? limit,
  }) {
    return where(
          (room) => room.isNotSpaceAndStoryRoom() && room.isShowInChatList(),
        )
        .map((room) => room.toRecentChatSearchModel(matrixLocalizations))
        .where((model) => _matchedNameOrMatrixId(model, keyword))
        .take(limit ?? length)
        .toList();
  }
}
