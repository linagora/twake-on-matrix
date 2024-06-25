import 'package:fluffychat/domain/model/app_grid/linagora_app.dart';

extension LinagoraAppExtension on LinagoraApp {
  String getDisplayAppName() {
    switch (appName) {
      case 'Twake Mail':
        return 'Mail';
      case 'Twake Drive':
        return 'Drive';
      default:
        return appName;
    }
  }
}
