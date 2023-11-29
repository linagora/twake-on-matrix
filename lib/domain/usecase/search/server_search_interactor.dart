import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/search/server_search_state.dart';
import 'package:fluffychat/domain/repository/server_search_repository.dart';
import 'package:matrix/matrix.dart';

class ServerSearchInteractor {
  final ServerSearchRepository _repository =
      getIt.get<ServerSearchRepository>();

  Stream<Either<Failure, Success>> execute({
    String? nextBatch,
    required String searchTerm,
    List<KeyKind>? keys = const [KeyKind.contentBody],
    SearchOrder orderBy = SearchOrder.recent,
    List<GroupKey> groupKeys = const [GroupKey.roomId],
  }) async* {
    try {
      yield Right(ServerSearchInitial());
      final response = await _repository.search(
        nextBatch: nextBatch,
        searchCategories: Categories(
          roomEvents: RoomEventsCriteria(
            searchTerm: searchTerm,
            groupings: Groupings(
              groupBy: groupKeys.map((e) => Group(key: e)).toList(),
            ),
            keys: keys,
            orderBy: orderBy,
          ),
        ),
      );

      final roomEventsResult = response.searchCategories.roomEvents;
      yield Right(
        ServerSearchChatSuccess(
          results: roomEventsResult?.results,
        ),
      );
    } catch (e) {
      Logs().d(
        'ServerSearchInteractor::execute(): Exception - $e}.',
      );
      yield Left(ServerSearchChatFailed(exception: e));
    }
  }
}
