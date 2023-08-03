import 'package:fluffychat/domain/model/extensions/search/search_extension.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/domain/model/search/search_model.dart';
import 'package:matrix/matrix.dart';

extension RoomListExtension on List<Room> {
  List<SearchModel> toSearchList(MatrixLocalizations matrixLocalizations) {
    return map((room) => room.toSearch(matrixLocalizations)).toList();
  }

  List<SearchModel> searchRecentChat({ 
    required MatrixLocalizations matrixLocalizations, 
    required String keyword,
    int? limit
  }) {
    final validRooms = where(
      (room) => room.isNotSpaceAndStoryRoom() && room.isShowInChatList()
    ).toList();
    final chatModels = validRooms.toSearchList(matrixLocalizations);
    if (keyword.isNotEmpty) {
      chatModels.removeWhere((chat) => !chat.searchDisplayName(keyword));
    }
    if (limit != null) {
      return chatModels.take(limit).toList();
    }
    return chatModels;
  }
}