import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/pages/chat_details/chat_details_page_view/same_type_events_list_controller.dart';
import 'package:fluffychat/widgets/twake_components/twake_smart_refresher.dart';

class SameTypeEventsListBuilder extends StatelessWidget {
  final SameTypeEventsListController controller;
  final Future<Timeline> Function() getTimeline;
  final Widget Function(BuildContext, Either<Failure, Success>) builder;

  const SameTypeEventsListBuilder({
    Key? key,
    required this.controller,
    required this.getTimeline,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.eventsNotifier,
      builder: (context, eventsState, child) => TwakeSmartRefresher(
        controller: controller.refreshController,
        onRefresh: () => controller.refresh(getTimeline: getTimeline),
        onLoading: () => controller.loadMore(getTimeline: getTimeline),
        child: builder(
          context,
          eventsState,
        ),
      ),
    );
  }
}
