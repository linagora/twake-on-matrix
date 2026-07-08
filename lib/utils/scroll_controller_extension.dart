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

  /// Whether [itemContext]'s row has a finite position in this controller's viewport.
  bool hasFiniteViewportPosition(BuildContext itemContext) {
    if (!hasClients) return false;
    final itemBox = itemContext.findRenderObject() as RenderBox?;
    final scrollBox =
        position.context.notificationContext?.findRenderObject() as RenderBox?;
    if (itemBox == null || scrollBox == null) return false;
    return itemBox.localToGlobal(Offset.zero, ancestor: scrollBox).dy.isFinite;
  }
}
