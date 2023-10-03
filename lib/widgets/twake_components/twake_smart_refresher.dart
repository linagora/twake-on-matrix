import 'package:flutter/material.dart';

import 'package:fluffychat/utils/scroll_controller_extension.dart';

class TwakeSmartRefresher extends StatefulWidget {
  final TwakeRefreshController controller;
  final Function? onRefresh;
  final Function? onLoading;
  final List<Widget> slivers;

  const TwakeSmartRefresher({
    Key? key,
    this.onRefresh,
    this.onLoading,
    required this.controller,
    required this.slivers,
  }) : super(key: key);

  @override
  State<TwakeSmartRefresher> createState() => _TwakeSmartRefresherController();
}

class TwakeRefreshController {
  final refreshNotifier = ValueNotifier(false);
  final loadNotifier = ValueNotifier(false);
  final scrollController = ScrollController();

  bool get isRefeshing => refreshNotifier.value;
  bool get isLoading => loadNotifier.value;

  void onRefresh() {
    refreshNotifier.value = true;
  }

  void refreshCompleted() {
    refreshNotifier.value = false;
  }

  void onLoading() {
    loadNotifier.value = true;
  }

  void loadComplete() {
    loadNotifier.value = false;
  }
}

class _TwakeSmartRefresherController extends State<TwakeSmartRefresher> {
  ScrollController get scrollController => widget.controller.scrollController;

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
    if (widget.controller.isRefeshing) return;
    widget.controller.onRefresh();
    widget.onRefresh?.call();
  }

  Future<void> onLoading() async {
    if (widget.controller.isLoading) return;
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
              child: refreshing ? const _LoadingIndicator() : const SizedBox(),
            ),
          ),
          ...slivers,
          ValueListenableBuilder(
            valueListenable: refreshController.loadNotifier,
            builder: (context, loading, child) => SliverToBoxAdapter(
              child: loading ? const _LoadingIndicator() : const SizedBox(),
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
