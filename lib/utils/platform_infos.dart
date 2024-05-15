import 'dart:io';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_html/html.dart' as html;
import '../config/app_config.dart';

abstract class PlatformInfos {
  static bool get isWeb => kIsWeb;

  static bool get isLinux => !kIsWeb && Platform.isLinux;

  static bool get isWindows => !kIsWeb && Platform.isWindows;

  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  static bool get isIOS => !kIsWeb && Platform.isIOS;

  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  static bool get isCupertinoStyle => isIOS || isMacOS;

  static bool get isMobile => isAndroid || isIOS;

  /// For desktops which don't support ChachedNetworkImage yet
  static bool get isBetaDesktop => isWindows || isLinux;

  static bool get isDesktop => isLinux || isWindows || isMacOS;

  static bool get usesTouchscreen => !isMobile;

  static bool get platformCanRecord => (isMobile || isMacOS);

  static bool get isMacKeyboardPlatform => isMacOS || isWebInMac;

  static bool get isWebInMac =>
      kIsWeb &&
      html.window.navigator.platform != null &&
      html.window.navigator.platform!.toLowerCase().contains('mac');

  static bool get isFireFoxBrowser =>
      kIsWeb &&
      html.window.navigator.userAgent.toLowerCase().contains('firefox');

  static String get clientName =>
      '${AppConfig.applicationName} ${isWeb ? 'web' : Platform.operatingSystem}${kReleaseMode ? '' : 'Debug'}';

  static Future<String> getVersion() async {
    var version = kIsWeb ? 'Web' : 'Unknown';
    try {
      version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}
    return version;
  }

  static void showAboutDialogFullScreen() async {
    final version = await PlatformInfos.getVersion();
    final twakeContext = TwakeApp.routerKey.currentContext;
    if (twakeContext == null) {
      Logs().e(
        'PlatformInfos()::showAboutDialogFullScreen - Twake context is null',
      );
      return;
    }
    showAboutDialog(
      context: twakeContext,
      useRootNavigator: false,
      children: [
        Text('Version: $version'),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(
            onPressed: () =>
                UrlLauncher(twakeContext, url: AppConfig.sourceCodeUrl)
                    .openUrlInAppBrowser(),
            child: Text(L10n.of(twakeContext)!.sourceCode),
          ),
        ),
        OutlinedButton(
          onPressed: () {
            twakeContext.go('/logs');
            Navigator.of(twakeContext).pop();
          },
          child: const Text('Logs'),
        ),
      ],
      applicationIcon: SvgPicture.asset(
        'assets/logo.svg',
        width: 56,
        height: 56,
        fit: BoxFit.fill,
      ),
      applicationName: AppConfig.applicationName,
    );
  }
}
