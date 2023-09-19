import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/timeline_search_event_state.dart';
import 'package:matrix/matrix.dart';

class TimelineSearchEventInteractor {
  Stream<Either<Failure, Success>> execute({
    required Timeline timeline,
    required bool Function(Event) searchFunc,
    required int requestHistoryCount,
    required int maxHistoryRequests,
    required int? limit,
    String? sinceEventId,
  }) async* {
    try {
      yield* timeline
          .searchEvent(
            searchFunc: searchFunc,
            requestHistoryCount: requestHistoryCount,
            maxHistoryRequests: maxHistoryRequests,
            limit: limit,
            sinceEventId: sinceEventId,
          )
          .map(_convertEventToSuccess);
    } catch (e) {
      yield Left(TimelineSearchEventFailure(exception: e));
    }
  }

  Either<Failure, Success> _convertEventToSuccess(events) {
    Logs().v(
      'TimelineSearchEventInteractor::events ${events.length} ${events.map((event) => event.eventId)}',
    );
    return Right(TimelineSearchEventSuccess(events: events));
  }
}
