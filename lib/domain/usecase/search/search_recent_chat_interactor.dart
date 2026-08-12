import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/app_state/search/search_state.dart';
import 'package:twake_chat/domain/model/room/room_list_extension.dart';
import 'package:matrix/matrix.dart';

class SearchRecentChatInteractor {
  SearchRecentChatInteractor();

  Stream<Either<Failure, Success>> execute({
    required List<Room> rooms,
    required MatrixLocalizations matrixLocalizations,
    required String keyword,
    int? limit,
  }) async* {
    try {
      final recentChat = rooms.searchRecentChat(
        matrixLocalizations: matrixLocalizations,
        keyword: keyword,
        limit: limit,
      );
      yield Right(SearchRecentChatSuccess(data: recentChat, keyword: keyword));
    } catch (e) {
      yield Left(SearchRecentChatFailed(exception: e));
    }
  }
}
