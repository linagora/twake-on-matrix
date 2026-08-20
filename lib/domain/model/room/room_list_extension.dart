import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/domain/model/search/recent_chat_model.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/search/simple_matcher_2.dart';
import 'package:matrix/matrix.dart';

extension RoomListExtension on List<Room> {
  List<RecentChatSearchModel> searchRecentChat({
    required MatrixLocalizations matrixLocalizations,
    required String keyword,
    int? limit,
  }) {
    final models = where(
      (room) => room.isNotSpaceAndStoryRoom() && room.isShowInChatList(),
    ).map((room) => room.toRecentChatSearchModel(matrixLocalizations)).toList();

    final matched = getIt.get<SimpleMatcher2>().match(
      keyword,
      models,
      fieldExtractors: [
        (RecentChatSearchModel m) => [m.displayName ?? ''],
        (RecentChatSearchModel m) => [m.directChatMatrixID ?? ''],
      ],
    );

    return matched.take(limit ?? matched.length).toList();
  }
}
