import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/timeline_search_event_state.dart';
import 'package:fluffychat/domain/usecase/room/timeline_search_event_interactor.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

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
  final emptyNotifier = ValueNotifier(false);

  StreamSubscription? _refreshSubscription;
  StreamSubscription? _loadMoreSubscription;
  UniqueKey? _refreshKey;
  UniqueKey? _loadMoreKey;

  final _searchInteractor = getIt.get<TimelineSearchEventInteractor>();
  var _isEnd = true;

  SameTypeEventsBuilderController({
    required this.getTimeline,
    required this.searchFunc,
    this.limit,
  });

  Future refresh({bool force = false}) async {
    if (refreshing.value && !force) return;
    emptyNotifier.value = false;
    refreshing.value = true;
    final timeline = await getTimeline();
    await _refreshSubscription?.cancel();
    final key = UniqueKey();
    _refreshKey = key;
    _refreshSubscription = _searchInteractor
        .execute(
          timeline: timeline,
          searchFunc: searchFunc,
          requestHistoryCount: _requestHistoryCount,
          maxHistoryRequests: _maxHistoryRequests,
          limit: limit,
        )
        .listen(
          (events) => _onRefreshSuccess(key, events),
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
    emptyNotifier.value = false;
    loadingMore.value = true;
    final timeline = await getTimeline();
    await _loadMoreSubscription?.cancel();
    final key = UniqueKey();
    _loadMoreKey = key;
    _loadMoreSubscription = _searchInteractor
        .execute(
          timeline: timeline,
          searchFunc: searchFunc,
          requestHistoryCount: _requestHistoryCount,
          maxHistoryRequests: _maxHistoryRequests,
          limit: limit,
          sinceEventId: lastSuccess.events.last.eventId,
        )
        .listen(
          (event) => _onLoadMoreSuccess(key, event, lastSuccess),
          onDone: _onLoadMoreDone,
        );
  }

  void clear() {
    _refreshSubscription?.cancel();
    _loadMoreSubscription?.cancel();
    _loadMoreKey = null;
    _refreshKey = null;
    refreshing.value = false;
    loadingMore.value = false;
    emptyNotifier.value = false;
    eventsNotifier.value = Right(TimelineSearchEventInitial());
  }

  void _onRefreshDone() {
    Logs().v('SameTypeEventsListController::refresh done');
    refreshing.value = false;
    emptyNotifier.value = eventsNotifier.value
            .getSuccessOrNull<TimelineSearchEventSuccess>()
            ?.events
            .isEmpty ??
        false;
  }

  void _onRefreshSuccess(UniqueKey key, Either<Failure, Success> event) {
    if (key != _refreshKey) return;
    Logs().v('SameTypeEventsListController::refresh $event');
    eventsNotifier.value = event;
    final success = event.getSuccessOrNull<TimelineSearchEventSuccess>();
    if (success != null && limit != null) {
      _isEnd = success.events.length < limit!;
    }
  }

  void _onLoadMoreSuccess(
    UniqueKey key,
    Either<Failure, Success> event,
    TimelineSearchEventSuccess lastSuccess,
  ) {
    if (key != _loadMoreKey) return;
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
    _refreshSubscription?.cancel();
    _loadMoreSubscription?.cancel();
  }
}
