import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/timeline_search_event_state.dart';
import 'package:fluffychat/domain/usecase/room/timeline_search_event_interactor.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class SameTypeEventsListController {
  static const _requestHistoryCount = 100;
  static const _maxHistoryRequests = 10;

  final bool Function(Event) searchFunc;
  final int? limit;

  SameTypeEventsListController({
    required this.searchFunc,
    required this.limit,
  });

  final eventsNotifier = ValueNotifier<Either<Failure, Success>>(
    Right(TimelineSearchEventInitial()),
  );
  final refreshController = RefreshController(initialRefresh: true);

  final _searchInteractor = getIt.get<TimelineSearchEventInteractor>();

  void refresh({required Future<Timeline> Function() getTimeline}) async {
    final timeline = await getTimeline();
    _searchInteractor
        .execute(
      timeline: timeline,
      searchFunc: searchFunc,
      requestHistoryCount: _requestHistoryCount,
      maxHistoryRequests: _maxHistoryRequests,
      limit: limit,
    )
        .listen(
      (event) {
        Logs().v('SameTypeEventsListController::refresh $event');
        eventsNotifier.value = event;
      },
      onError: (_) {
        refreshController.refreshFailed();
      },
      onDone: () {
        refreshController.refreshCompleted();
      },
    );
  }

  void loadMore({required Future<Timeline> Function() getTimeline}) async {
    final lastSuccess = eventsNotifier.value.getSuccessOrNull();
    if (lastSuccess == null || lastSuccess.events.isEmpty) {
      refreshController.loadComplete();
      return;
    }
    final timeline = await getTimeline();
    var isEnd = false;
    _searchInteractor
        .execute(
      timeline: timeline,
      searchFunc: searchFunc,
      requestHistoryCount: _requestHistoryCount,
      maxHistoryRequests: _maxHistoryRequests,
      limit: limit,
      sinceEventId: lastSuccess.events.last.eventId,
    )
        .listen(
      (event) {
        Logs().v('SameTypeEventsListController::loadMore $event');
        eventsNotifier.value = event.map(
          (success) {
            if (success is TimelineSearchEventSuccess) {
              isEnd = limit != null
                  ? success.events.length < limit!
                  : success.events.isEmpty;
              return lastSuccess.concat(success);
            }
            return success;
          },
        );
      },
      onError: (_) {
        refreshController.loadFailed();
      },
      onDone: () {
        if (isEnd) {
          Logs().v('SameTypeEventsListController::loadMore loadNoData');
          refreshController.loadNoData();
        } else {
          Logs().v('SameTypeEventsListController::loadMore loadComplete');
          refreshController.loadComplete();
        }
      },
    );
  }
}
