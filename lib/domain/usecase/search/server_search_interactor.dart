import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/search/server_search_state.dart';
import 'package:twake_chat/domain/model/search/server_side_search_categories.dart';
import 'package:twake_chat/domain/repository/server_search_repository.dart';
import 'package:matrix/matrix.dart';

class ServerSearchInteractor {
  final ServerSearchRepository _repository = getIt
      .get<ServerSearchRepository>();

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
      Logs().e('ServerSearchInteractor::execute(): Exception - $e}.');
      yield Left(ServerSearchChatFailed(exception: e));
    }
  }
}
