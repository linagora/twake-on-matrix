import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/search/server_search_state.dart';
import 'package:fluffychat/domain/model/search/server_side_search_categories.dart';
import 'package:fluffychat/domain/repository/server_search_repository.dart';
import 'package:matrix/matrix.dart';

class ServerSearchInteractor {
  final ServerSearchRepository _repository =
      getIt.get<ServerSearchRepository>();

  Stream<Either<Failure, Success>> execute({
    required ServerSideSearchCategories searchCategories,
    String? nextBatch,
  }) async* {
    try {
      if (nextBatch == null) {
        yield Right(ServerSearchInitial());
      }
      final response = await _repository.search(
        nextBatch: nextBatch,
        searchCategories: searchCategories.searchCategories,
      );

      final roomEventsResult = response.searchCategories.roomEvents;

      Logs().d(
        'ServerSearchInteractor::execute(): Search success - ${response.searchCategories.roomEvents?.results?.length}.',
      );

      yield Right(
        ServerSearchChatSuccess(
          results: roomEventsResult?.results,
          nextBatch: roomEventsResult?.nextBatch,
        ),
      );
    } catch (e) {
      Logs().e(
        'ServerSearchInteractor::execute(): Exception - $e}.',
      );
      yield Left(ServerSearchChatFailed(exception: e));
    }
  }
}
