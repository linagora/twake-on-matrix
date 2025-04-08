import 'package:linagora_design_flutter/cozy_config_manager/cozy_config_manager.dart';
import 'package:universal_html/html.dart';

class CozyConfig {
  static final CozyConfig instance = CozyConfig._internal();
  CozyConfig._internal();

  static const cozyBridgeVersion = '0.7.0';

  final manager = CozyConfigManager();

  bool _isCozyScriptInjected = false;

  void injectCozyScript() {
    if (_isCozyScriptInjected) {
      return;
    }

    final ScriptElement script = ScriptElement();
    script.src =
        'https://cdn.jsdelivr.net/npm/cozy-external-bridge@$cozyBridgeVersion/dist/embedded/bundle.js';
    document.head?.append(script);
    _isCozyScriptInjected = true;
  }
}
