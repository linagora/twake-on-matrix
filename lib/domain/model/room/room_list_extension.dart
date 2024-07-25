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
          (model) {
            final matchedMatrixId = model.directChatMatrixID
                    ?.toLowerCase()
                    .contains(keyword.toLowerCase()) ??
                false;

            final matchedName = model.displayName
                    ?.toLowerCase()
                    .contains(keyword.toLowerCase()) ??
                false;

            return matchedName || matchedMatrixId;
          },
        )
        .take(limit ?? length)
        .toList();
  }
}
