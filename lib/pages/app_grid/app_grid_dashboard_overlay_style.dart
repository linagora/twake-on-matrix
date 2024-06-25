import 'package:fluffychat/domain/model/app_grid/linagora_applications.dart';
import 'package:fluffychat/pages/app_grid/app_grid_dashboard_item_style.dart';
import 'package:flutter/material.dart';

class AppGridDashboardOverlayStyle {
  static double widthAppGrid(LinagoraApplications linagoraApplications) {
    if (linagoraApplications.apps.length >= 3) {
      return AppGridDashboardItemStyle.itemWidth * 3 + padding.horizontal;
    } else if (linagoraApplications.apps.length == 2) {
      return AppGridDashboardItemStyle.itemWidth * 2 + padding.horizontal;
    } else {
      return AppGridDashboardItemStyle.itemWidth + padding.horizontal;
    }
  }

  static List<BoxShadow> boxShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      offset: const Offset(0, 0),
      blurRadius: 20,
    ),
  ];

  static const double borderRadius = 14;

  static const EdgeInsets padding =
      EdgeInsets.symmetric(vertical: 14, horizontal: 10);
}
