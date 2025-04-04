import 'package:linagora_design_flutter/cozy_config_manager/cozy_config_manager.dart';
import 'package:universal_html/html.dart';

class CozyConfig {
  static final CozyConfig instance = CozyConfig._internal();
  CozyConfig._internal();

  final manager = CozyConfigManager();

  bool _isCozyScriptInjected = false;

  void injectCozyScript() {
    if (_isCozyScriptInjected) {
      return;
    }

    final ScriptElement script = ScriptElement();
    script.src =
        'https://cdn.jsdelivr.net/npm/cozy-external-bridge@0.6.0/dist/embedded/bundle.js';
    document.head?.append(script);
    _isCozyScriptInjected = true;
  }
}
