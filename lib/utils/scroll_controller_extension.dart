import 'package:flutter/material.dart';

extension ScrollControllerExtension on ScrollController {
  bool get shouldLoadMore {
    return position.extentAfter < 500;
  }
}