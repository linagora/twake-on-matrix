import 'package:twake_chat/domain/model/room/room_extension.dart';
import 'package:twake_chat/domain/model/search/recent_chat_model.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/utils/search/search_engine.dart';
import 'package:twake_chat/utils/search/search_options.dart';
import 'package:matrix/matrix.dart';

const _searchOptions = SearchOptions(diacriticSensitive: false);

extension RoomListExtension on List<Room> {
  List<RecentChatSearchModel> searchRecentChat({
    required MatrixLocalizations matrixLocalizations,
    required String keyword,
    int? limit,
  }) {
    final models = where(
      (room) => room.isNotSpaceAndStoryRoom() && room.isShowInChatList(),
    ).map((room) => room.toRecentChatSearchModel(matrixLocalizations)).toList();

    final matched = getIt.get<SearchEngine>().match(
      keyword,
      models,
      fieldExtractors: [
        (RecentChatSearchModel m) => [m.displayName ?? ''],
        (RecentChatSearchModel m) => [m.directChatMatrixID ?? ''],
      ],
      options: _searchOptions,
    );

    return matched.take(limit ?? matched.length).toList();
  }
}
