import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

extension ScrollControllerExtension on ScrollController {
  static const endReachedDistance = 500;
  bool get shouldLoadMore {
    return position.extentAfter < endReachedDistance;
  }

  void addLoadMoreListener(VoidCallback listener) {
    addListener(() {
      if (shouldLoadMore) {
        listener();
      }
    });
  }

  void tryLoadMoreIfNeeded(VoidCallback loadMore) {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (shouldLoadMore) {
        loadMore();
      }
    });
  }
}
