import 'dart:async';
import 'package:fluffychat/pages/bootstrap/init_client_dialog.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:lottie/lottie.dart';
import 'package:matrix/matrix.dart';

class TwakeDialog {
  static const double maxWidthLoadingDialogWeb = 448;

  static const double lottieSizeWeb = 80;

  static const double lottieSizeMobile = 48;

  static void hideLoadingDialog(BuildContext context) {
    if (PlatformInfos.isWeb) {
      TwakeApp.router.routerDelegate.pop();
    } else {
      Navigator.pop(context);
    }
  }

  static void showLoadingDialog(BuildContext context) {
    showGeneralDialog(
      barrierColor: Colors.black.withOpacity(0.1),
      useRootNavigator: PlatformInfos.isWeb,
      transitionDuration: const Duration(milliseconds: 700),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(animation),
          child: PopScope(
            canPop: false,
            child: ProgressDialog(
              lottieSize:
                  PlatformInfos.isWeb ? lottieSizeWeb : lottieSizeMobile,
            ),
          ),
        );
      },
      context: context,
      pageBuilder: (c, a1, a2) {
        return const SizedBox();
      },
    );
  }

  static Future<LoadingDialogResult<T>> showFutureLoadingDialogFullScreen<T>({
    required Future<T> Function() future,
  }) async {
    final twakeContext = TwakeApp.routerKey.currentContext;
    if (twakeContext == null) {
      Logs().e(
        'TwakeLoadingDialog()::showFutureLoadingDialogFullScreen - Twake context is null',
      );
      return LoadingDialogResult<T>(
        error: Exception('FutureDialog canceled'),
        stackTrace: StackTrace.current,
      );
    }
    return await showFutureLoadingDialog(
      context: twakeContext,
      future: future,
      loadingIcon: LottieBuilder.asset(
        'assets/twake_loading.json',
        width: PlatformInfos.isWeb ? lottieSizeWeb : lottieSizeMobile,
        height: PlatformInfos.isWeb ? lottieSizeWeb : lottieSizeMobile,
      ),
      barrierColor: Colors.black.withOpacity(0.1),
      loadingTitle: L10n.of(twakeContext)!.loading,
      loadingTitleStyle: PlatformInfos.isWeb
          ? Theme.of(twakeContext).textTheme.titleLarge
          : Theme.of(twakeContext).textTheme.titleMedium,
      maxWidth: !PlatformInfos.isMobile ? maxWidthLoadingDialogWeb : null,
      errorTitle: L10n.of(twakeContext)!.errorDialogTitle,
      errorTitleStyle: PlatformInfos.isWeb
          ? Theme.of(twakeContext).textTheme.titleLarge
          : Theme.of(twakeContext).textTheme.titleMedium,
      errorBackLabel: L10n.of(twakeContext)!.cancel,
      errorBackLabelStyle: PlatformInfos.isWeb
          ? Theme.of(twakeContext).textTheme.titleLarge?.copyWith(
                color: Theme.of(twakeContext).colorScheme.primary,
              )
          : Theme.of(twakeContext).textTheme.titleMedium?.copyWith(
                color: Theme.of(twakeContext).colorScheme.primary,
              ),
      errorNextLabel: L10n.of(twakeContext)!.next,
      errorNextLabelStyle: PlatformInfos.isWeb
          ? Theme.of(twakeContext).textTheme.titleLarge?.copyWith(
                color: Theme.of(twakeContext).colorScheme.onPrimary,
              )
          : Theme.of(twakeContext).textTheme.titleMedium?.copyWith(
                color: Theme.of(twakeContext).colorScheme.onPrimary,
              ),
      backgroundNextLabel: Theme.of(twakeContext).colorScheme.primary,
    );
  }

  static Future<void> showStreamDialogFullScreen({
    required Future Function() future,
  }) async {
    final twakeContext = TwakeApp.routerKey.currentContext;
    if (twakeContext == null) {
      Logs().e(
        'TwakeLoadingDialog()::showStreamDialogFullScreen - Twake context is null',
      );
    }
    return await showDialog(
      context: twakeContext!,
      builder: (context) => InitClientDialog(
        future: future,
      ),
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      useRootNavigator: false,
    );
  }

  static Future<bool?> showDialogFullScreen({
    required Widget Function() builder,
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    final twakeContext = TwakeApp.routerKey.currentContext;
    if (twakeContext == null) {
      Logs().e(
        'TwakeLoadingDialog()::showDialogFullScreen - Twake context is null',
      );
      return Future.value(null);
    }
    return showDialog(
      context: twakeContext,
      builder: (context) => builder(),
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
      useRootNavigator: false,
    );
  }

  static Future<bool?> showCupertinoDialogFullScreen({
    required Widget Function() builder,
  }) {
    final twakeContext = TwakeApp.routerKey.currentContext;
    if (twakeContext == null) {
      Logs().e(
        'TwakeLoadingDialog()::showCupertinoDialogFullScreen - Twake context is null',
      );
      return Future.value(null);
    }
    return showCupertinoDialog(
      context: twakeContext,
      builder: (context) => builder(),
      barrierDismissible: true,
      useRootNavigator: false,
    );
  }
}

class ProgressDialog extends StatelessWidget {
  final double lottieSize;

  const ProgressDialog({
    super.key,
    required this.lottieSize,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LottieBuilder.asset(
            'assets/twake_loading.json',
            width: lottieSize,
            height: lottieSize,
          ),
          const SizedBox(height: 24),
          Text(
            L10n.of(context)!.loading,
            style: PlatformInfos.isWeb
                ? Theme.of(context).textTheme.titleLarge
                : Theme.of(context).textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
