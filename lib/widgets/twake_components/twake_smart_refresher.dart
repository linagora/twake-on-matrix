import 'package:fluffychat/widgets/twake_components/twake_loading/center_loading_indicator.dart';
import 'package:flutter/material.dart';

import 'package:fluffychat/utils/scroll_controller_extension.dart';

class TwakeSmartRefresher extends StatefulWidget {
  final TwakeRefreshController controller;
  final Function? onRefresh;
  final Function? onLoading;
  final List<Widget> slivers;

  const TwakeSmartRefresher({
    super.key,
    this.onRefresh,
    this.onLoading,
    required this.controller,
    required this.slivers,
  });

  @override
  State<TwakeSmartRefresher> createState() => _TwakeSmartRefresherController();
}

class TwakeRefreshController {
  final refreshNotifier = ValueNotifier(false);
  final loadingNotifier = ValueNotifier(false);

  bool get isRefeshing => refreshNotifier.value;
  bool get isLoading => loadingNotifier.value;

  void onRefresh() {
    refreshNotifier.value = true;
  }

  void refreshCompleted() {
    refreshNotifier.value = false;
  }

  void onLoading() {
    loadingNotifier.value = true;
  }

  void loadComplete() {
    loadingNotifier.value = false;
  }
}

class _TwakeSmartRefresherController extends State<TwakeSmartRefresher> {
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addLoadMoreListener(onLoading);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Future<void> onRefresh() async {
    if (widget.controller.isRefeshing || widget.onRefresh == null) return;
    widget.controller.onRefresh();
    widget.onRefresh?.call();
  }

  Future<void> onLoading() async {
    if (widget.controller.isLoading || widget.onLoading == null) return;
    widget.controller.onLoading();
    await widget.onLoading!();
  }

  @override
  Widget build(BuildContext context) {
    return _TwakeSmartRefresherView(
      controller: this,
      refreshController: widget.controller,
      slivers: widget.slivers,
    );
  }
}

class _TwakeSmartRefresherView extends StatelessWidget {
  const _TwakeSmartRefresherView({
    required this.controller,
    required this.refreshController,
    required this.slivers,
  });
  final List<Widget> slivers;
  final TwakeRefreshController refreshController;
  final _TwakeSmartRefresherController controller;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.onRefresh,
      child: CustomScrollView(
        controller: controller.scrollController,
        slivers: [
          ValueListenableBuilder(
            valueListenable: refreshController.refreshNotifier,
            builder: (context, refreshing, child) => SliverToBoxAdapter(
              child: refreshing
                  ? const CenterLoadingIndicator()
                  : const SizedBox(),
            ),
          ),
          ...slivers,
          ValueListenableBuilder(
            valueListenable: refreshController.loadingNotifier,
            builder: (context, loading, child) => SliverToBoxAdapter(
              child:
                  loading ? const CenterLoadingIndicator() : const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }
}
