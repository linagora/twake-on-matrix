import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class TwakeSmartRefresher extends StatelessWidget {
  final RefreshController controller;
  final VoidCallback onRefresh;
  final VoidCallback onLoading;
  final Widget? child;

  const TwakeSmartRefresher({
    Key? key,
    required this.controller,
    required this.onRefresh,
    required this.onLoading,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      enablePullUp: true,
      header: CustomHeader(
        builder: (context, mode) {
          if (mode != RefreshStatus.refreshing) {
            return const SizedBox.shrink();
          }
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
      footer: CustomFooter(
        builder: (context, mode) {
          if (mode != LoadStatus.loading) {
            return const SizedBox.shrink();
          }
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
      controller: controller,
      onRefresh: onRefresh,
      onLoading: onLoading,
      child: child,
    );
  }
}
