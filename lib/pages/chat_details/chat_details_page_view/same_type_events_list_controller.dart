import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/utils/scroll_controller_extension.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/timeline_search_event_state.dart';
import 'package:fluffychat/domain/usecase/room/timeline_search_event_interactor.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/same_type_events_list_builder_view.dart';

class SameTypeEventsListBuilder extends StatefulWidget {
  final Future<Timeline> Function() getTimeline;
  final bool Function(Event) searchFunc;
  final int? limit;

  /// The builder must return a sliver.
  final Widget Function(BuildContext, Either<Failure, Success>) builder;

  const SameTypeEventsListBuilder({
    Key? key,
    required this.getTimeline,
    required this.searchFunc,
    this.limit,
    required this.builder,
  }) : super(key: key);

  @override
  State<SameTypeEventsListBuilder> createState() =>
      SameTypeEventsBuilderController();
}

class SameTypeEventsBuilderController extends State<SameTypeEventsListBuilder> {
  static const _requestHistoryCount = 100;
  static const _maxHistoryRequests = 10;

  final eventsNotifier = ValueNotifier<Either<Failure, Success>>(
    Right(TimelineSearchEventInitial()),
  );
  final scrollController = ScrollController();
  final refreshing = ValueNotifier(false);
  final loadingMore = ValueNotifier(false);

  final _searchInteractor = getIt.get<TimelineSearchEventInteractor>();
  var _isEnd = true;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
    refresh();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Future refresh() async {
    if (refreshing.value) return;
    refreshing.value = true;
    final timeline = await widget.getTimeline();
    _searchInteractor
        .execute(
          timeline: timeline,
          searchFunc: widget.searchFunc,
          requestHistoryCount: _requestHistoryCount,
          maxHistoryRequests: _maxHistoryRequests,
          limit: widget.limit,
        )
        .listen(
          _onRefreshSuccess,
          onDone: _onRefreshDone,
        );
  }

  void _loadMore() async {
    final lastSuccess =
        eventsNotifier.value.getSuccessOrNull<TimelineSearchEventSuccess>();
    if (lastSuccess == null ||
        refreshing.value ||
        loadingMore.value ||
        _isEnd) {
      return;
    }
    loadingMore.value = true;
    final timeline = await widget.getTimeline();
    _searchInteractor
        .execute(
          timeline: timeline,
          searchFunc: widget.searchFunc,
          requestHistoryCount: _requestHistoryCount,
          maxHistoryRequests: _maxHistoryRequests,
          limit: widget.limit,
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
    if (success != null && widget.limit != null) {
      _isEnd = success.events.length < widget.limit!;
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
          _isEnd = widget.limit != null
              ? success.events.length < widget.limit!
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

  void _onScroll() {
    if (scrollController.shouldLoadMore) {
      _loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SameTypeEventsListBuilderView(controller: this);
  }
}
