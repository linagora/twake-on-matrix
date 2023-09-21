import 'package:fluffychat/pages/chat_details/chat_details_page_view/same_type_events_list_controller.dart';
import 'package:flutter/material.dart';

class SameTypeEventsListBuilderView extends StatelessWidget {
  final SameTypeEventsBuilderController controller;

  const SameTypeEventsListBuilderView({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: CustomScrollView(
        controller: controller.scrollController,
        slivers: [
          ValueListenableBuilder(
            valueListenable: controller.refreshing,
            builder: (context, refreshing, child) => SliverToBoxAdapter(
              child: refreshing ? const _LoadingIndicator() : const SizedBox(),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: controller.eventsNotifier,
            builder: (context, eventsState, child) =>
                controller.widget.builder(context, eventsState),
          ),
          ValueListenableBuilder(
            valueListenable: controller.loadingMore,
            builder: (context, loadingMore, child) => SliverToBoxAdapter(
              child: loadingMore ? const _LoadingIndicator() : const SizedBox(),
            ),
          )
        ],
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
