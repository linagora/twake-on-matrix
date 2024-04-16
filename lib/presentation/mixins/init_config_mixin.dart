import 'package:fluffychat/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:matrix/matrix.dart';

mixin InitConfigMixin {
  Future<void> initConfigWeb() async {
    try {
      final configJsonString =
          utf8.decode((await http.get(Uri.parse('config.json'))).bodyBytes);
      final configJson = json.decode(configJsonString);
      AppConfig.loadFromJson(configJson);
      Logs().d('[ConfigLoader] $configJson');
      AppConfig.initConfigCompleter.complete(true);
    } on FormatException catch (_) {
      _retryInitConfigWeb();
      Logs().v('[ConfigLoader] config.json not found');
    } catch (e) {
      _retryInitConfigWeb();
      Logs().v('[ConfigLoader] config.json not found', e);
    }
  }

  void _retryInitConfigWeb() {
    if (!AppConfig.hasReachedMaxRetries) {
      AppConfig.retryCompleterCount++;
      initConfigWeb();
    } else {
      AppConfig.initConfigCompleter.complete(false);
    }
  }

  Future<void> initConfigMobile() async {
    try {
      AppConfig.loadEnvironment();
    } catch (e) {
      Logs().e('[ConfigLoader] Config mobile error', e);
    }
  }
}
