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
      await for (final events in timeline.searchEvent(
        searchFunc: searchFunc,
        requestHistoryCount: requestHistoryCount,
        maxHistoryRequests: maxHistoryRequests,
        limit: limit,
        sinceEventId: sinceEventId,
      )) {
        yield Right(TimelineSearchEventSuccess(events: List.from(events)));
      }
    } catch (e) {
      yield Left(TimelineSearchEventFailure(exception: e));
    }
  }
}
