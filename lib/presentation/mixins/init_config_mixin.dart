import 'package:twake_chat/config/app_config.dart';

import 'package:matrix/matrix.dart';

mixin InitConfigMixin {
  Future<void> initConfigMobile() async {
    var isConfigured = true;
    try {
      AppConfig.loadEnvironment();
    } catch (e) {
      isConfigured = false;
      Logs().e('[ConfigLoader] Config mobile error', e);
    }
    if (!AppConfig.initConfigCompleter.isCompleted) {
      AppConfig.initConfigCompleter.complete(isConfigured);
    }
  }
}
