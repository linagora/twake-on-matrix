import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/timeline_search_event_state.dart';
import 'package:fluffychat/domain/usecase/room/timeline_search_event_interactor.dart';

class SameTypeEventsBuilderController {
  final Future<Timeline> Function() getTimeline;
  final bool Function(Event) searchFunc;
  final int? limit;

  static const _requestHistoryCount = 100;
  static const _maxHistoryRequests = 10;

  final eventsNotifier = ValueNotifier<Either<Failure, Success>>(
    Right(TimelineSearchEventInitial()),
  );
  final refreshing = ValueNotifier(false);
  final loadingMore = ValueNotifier(false);

  StreamSubscription? _searchSubscription;

  final _searchInteractor = getIt.get<TimelineSearchEventInteractor>();
  var _isEnd = true;

  SameTypeEventsBuilderController({
    required this.getTimeline,
    required this.searchFunc,
    this.limit,
  });

  Future refresh() async {
    if (refreshing.value) return;
    refreshing.value = true;
    final timeline = await getTimeline();
    _searchSubscription = _searchInteractor
        .execute(
          timeline: timeline,
          searchFunc: searchFunc,
          requestHistoryCount: _requestHistoryCount,
          maxHistoryRequests: _maxHistoryRequests,
          limit: limit,
        )
        .listen(
          _onRefreshSuccess,
          onDone: _onRefreshDone,
        );
  }

  void loadMore() async {
    final lastSuccess =
        eventsNotifier.value.getSuccessOrNull<TimelineSearchEventSuccess>();
    if (lastSuccess == null ||
        refreshing.value ||
        loadingMore.value ||
        _isEnd) {
      return;
    }
    loadingMore.value = true;
    final timeline = await getTimeline();
    _searchSubscription = _searchInteractor
        .execute(
          timeline: timeline,
          searchFunc: searchFunc,
          requestHistoryCount: _requestHistoryCount,
          maxHistoryRequests: _maxHistoryRequests,
          limit: limit,
          sinceEventId: lastSuccess.events.last.eventId,
        )
        .listen(
          (event) => _onLoadMoreSuccess(event, lastSuccess),
          onDone: _onLoadMoreDone,
        );
  }

  void _onRefreshDone() {
    Logs().v('SameTypeEventsListController::refresh done');
    refreshing.value = false;
  }

  void _onRefreshSuccess(Either<Failure, Success> event) {
    Logs().v('SameTypeEventsListController::refresh $event');
    eventsNotifier.value = event;
    final success = event.getSuccessOrNull<TimelineSearchEventSuccess>();
    if (success != null && limit != null) {
      _isEnd = success.events.length < limit!;
    }
  }

  void _onLoadMoreSuccess(
    Either<Failure, Success> event,
    TimelineSearchEventSuccess lastSuccess,
  ) {
    Logs().v('SameTypeEventsListController::loadMore $event');
    eventsNotifier.value = event.map(
      (success) {
        if (success is TimelineSearchEventSuccess) {
          _isEnd = limit != null
              ? success.events.length < limit!
              : success.events.isEmpty;
          return lastSuccess.concat(success);
        }
        return success;
      },
    );
  }

  void _onLoadMoreDone() {
    loadingMore.value = false;
  }

  void dispose() {
    eventsNotifier.dispose();
    refreshing.dispose();
    loadingMore.dispose();
    _searchSubscription?.cancel();
  }
}
