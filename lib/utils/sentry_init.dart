import 'package:twake_chat/config/app_config.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix_api_lite/utils/logs.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> sentryInit({
  required void Function(Widget app) runApp,
  required Widget app,
}) async {
  if (kDebugMode) {
    Logs().i('sentryInit(): local build, Sentry disabled');
    runApp(app);
    return;
  }
  try {
    final info = await PackageInfo.fromPlatform();
    await AppConfig.loadSentryConfig();
    if (AppConfig.sentryDsn?.isNotEmpty ?? false) {
      await SentryFlutter.init((options) {
        options.dsn = AppConfig.sentryDsn;
        options.environment = AppConfig.sentryEnvironment;
        options.enableLogs = true;
        // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
        // We recommend adjusting this value in production.
        options.tracesSampleRate = 0.1;
        // The sampling rate for profiling is relative to tracesSampleRate
        // Setting to 1.0 will profile 100% of sampled transactions:
        // ignore: experimental_member_use
        options.profilesSampleRate = 0.1;

        options.release = info.version;
        options.dist = info.buildNumber;
      }, appRunner: () => runApp(SentryWidget(child: app)));
    } else {
      runApp(app);
    }
  } catch (e, s) {
    Logs().e('sentryInit():', e, s);
    runApp(app);
  }
}
