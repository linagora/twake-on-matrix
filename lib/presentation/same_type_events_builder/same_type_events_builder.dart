import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/presentation/same_type_events_builder/same_type_events_controller.dart';
import 'package:fluffychat/widgets/twake_components/twake_loading/center_loading_indicator.dart';
import 'package:flutter/material.dart';

class SameTypeEventsBuilder extends StatelessWidget {
  final SameTypeEventsBuilderController controller;
  final ScrollController? scrollController;

  /// The builder must return a sliver.
  final Widget Function(BuildContext, Either<Failure, Success>, Widget?)
      builder;

  const SameTypeEventsBuilder({
    super.key,
    required this.controller,
    required this.builder,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        ValueListenableBuilder(
          valueListenable: controller.refreshing,
          builder: (context, refreshing, child) => SliverToBoxAdapter(
            child:
                refreshing ? const CenterLoadingIndicator() : const SizedBox(),
          ),
        ),
        ValueListenableBuilder(
          valueListenable: controller.eventsNotifier,
          builder: builder,
        ),
        ValueListenableBuilder(
          valueListenable: controller.loadingMore,
          builder: (context, loadingMore, child) => SliverToBoxAdapter(
            child:
                loadingMore ? const CenterLoadingIndicator() : const SizedBox(),
          ),
        ),
      ],
    );
  }
}
