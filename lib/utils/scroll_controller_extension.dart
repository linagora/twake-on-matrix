import 'package:flutter/material.dart';

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
}
