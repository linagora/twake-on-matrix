import 'package:fluffychat/config/app_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> sentryInit({
  required void Function(Widget app) runApp,
  required Widget app,
}) async {
  final info = await PackageInfo.fromPlatform();
  await AppConfig.loadSentryConfig();
  if (AppConfig.sentryDsn?.isNotEmpty ?? false) {
    await SentryFlutter.init((options) {
      options.dsn = AppConfig.sentryDsn;
      options.environment = AppConfig.sentryEnvironment;
      options.enableLogs = true;
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = kDebugMode ? 1.0 : 0.1;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      options.profilesSampleRate = kDebugMode ? 1.0 : 0.1;
      options.beforeSend = _fixWebSourceMapPaths;

      options.release = info.version;
      options.dist = info.buildNumber;
    }, appRunner: () => runApp(SentryWidget(child: app)));
  } else {
    runApp(app);
  }
}

SentryEvent? _fixWebSourceMapPaths(SentryEvent event, Hint hint) {
  if (!kIsWeb) return event;

  final base = Uri.base;
  final basePath = base.path;
  if (basePath == '/') return event;

  final origin =
      '${base.scheme}://${base.host}'
      '${base.hasPort ? ':${base.port}' : ''}';

  for (final exception in event.exceptions ?? <SentryException>[]) {
    final frames = exception.stackTrace?.frames;
    if (frames == null) continue;
    for (final frame in frames) {
      final absPath = frame.absPath;
      if (absPath == null || !absPath.startsWith(origin)) continue;

      final pathPart = absPath.substring(origin.length);
      if (pathPart.startsWith(basePath)) continue;

      final file = pathPart.startsWith('/') ? pathPart.substring(1) : pathPart;
      frame.absPath = '$origin$basePath$file';
    }
  }
  return event;
}
