import 'package:fluffychat/domain/model/app_grid/linagora_applications.dart';
import 'package:flutter/cupertino.dart';

class AppGridDashboardOverlayStyle {
  static double widthAppGrid(LinagoraApplications linagoraApplications) {
    if (linagoraApplications.apps.length >= 3) {
      return 326;
    } else if (linagoraApplications.apps.length == 2) {
      return 228;
    } else if (linagoraApplications.apps.length == 1) {
      return 130;
    } else {
      return 0;
    }
  }

  static const double borderRadius = 24;

  static const EdgeInsets padding = EdgeInsets.all(16);

  static const EdgeInsets margin = EdgeInsets.only(right: 16);
}
