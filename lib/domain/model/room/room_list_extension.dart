import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/domain/model/search/recent_chat_model.dart';
import 'package:matrix/matrix.dart';

extension RoomListExtension on List<Room> {
  List<RecentChatSearchModel> searchRecentChat({
    required MatrixLocalizations matrixLocalizations,
    required String keyword,
    int? limit,
  }) {
    return where(
      (room) => room.isNotSpaceAndStoryRoom() && room.isShowInChatList(),
    )
        .map((room) => room.toRecentChatSearchModel(matrixLocalizations))
        .where(
          (model) =>
              model.displayName != null &&
              model.displayName!.toLowerCase().contains(
                    keyword.toLowerCase(),
                  ),
        )
        .take(limit ?? length)
        .toList();
  }
}
