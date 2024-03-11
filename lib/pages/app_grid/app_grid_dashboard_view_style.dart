import 'package:fluffychat/domain/model/app_grid/linagora_applications.dart';

class AppGridDashboardViewStyle {
  static const double sizIcAppGrid = 48.0;

  static double widthAppGrid(LinagoraApplications linagoraApplications) {
    if (linagoraApplications.apps.length >= 3) {
      return 342;
    } else if (linagoraApplications.apps.length == 2) {
      return 244;
    } else if (linagoraApplications.apps.length == 1) {
      return 146;
    } else {
      return 0;
    }
  }
}
