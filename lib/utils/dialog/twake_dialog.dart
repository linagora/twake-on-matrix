import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

class TwakeDialog {
  static void hideLoadingDialog(BuildContext context) {
    if (PlatformInfos.isWeb) {
      TwakeApp.router.routerDelegate.pop();
    } else {
      Navigator.pop(context);
    }
  }

  static void showLoadingDialog(BuildContext context) {
    showGeneralDialog(
      useRootNavigator: PlatformInfos.isWeb,
      transitionDuration: const Duration(milliseconds: 700),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(animation),
          child: const PopScope(
            canPop: false,
            child: ProgressDialog(),
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
    );
  }

  static Future<bool?> showDialogFullScreen({
    required Widget Function() builder,
    bool barrierDismissible = true,
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
  const ProgressDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircularProgressIndicator.adaptive(),
          ),
          Expanded(
            child: Text(
              L10n.of(context)!.loadingPleaseWait,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
