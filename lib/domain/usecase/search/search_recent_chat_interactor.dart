import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/search/search_interactor_state.dart';
import 'package:fluffychat/domain/model/room/room_list_extension.dart';
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
        limit: limit);
      yield Right(GetContactAndRecentChatSuccess(
        searchResult: recentChat, 
        shouldLoadMoreContacts: keyword.isNotEmpty,
        contactsOffset: 0,
        keyword: keyword,
      ));
    } catch (e) {
      yield Left(GetContactAndRecentChatFailed(exception: e));
    }
  }
}