import 'dart:async';
import 'package:animations/animations.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/bootstrap/init_client_dialog.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/dialog/confirmation_dialog_builder.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:matrix/matrix.dart';

class TwakeDialog {
  static const double maxWidthLoadingDialogWeb = 448;

  static const double lottieSizeWeb = 80;

  static const double lottieSizeMobile = 48;

  static ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  static const double maxWidthDialogButtonMobile = 112;

  static const double maxWidthDialogButtonWeb = 128;

  static const int defaultMaxLinesMessage = 3;

  static void hideLoadingDialog(BuildContext context) {
    if (PlatformInfos.isWeb) {
      if (TwakeApp.routerKey.currentContext != null) {
        Navigator.pop(TwakeApp.routerKey.currentContext!);
      } else {
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }
  }

  static void showLoadingTwakeWelcomeDialog(BuildContext context) {
    showGeneralDialog(
      barrierColor: LinagoraSysColors.material().onPrimary,
      useRootNavigator: false,
      transitionDuration: const Duration(milliseconds: 700),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(animation),
          child: const PopScope(
            canPop: false,
            child: ProgressDialog(
              lottieSize: lottieSizeMobile,
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

  static void showLoadingDialog(BuildContext context) {
    showGeneralDialog(
      barrierColor: LinagoraSysColors.material().onPrimary.withOpacity(0.75),
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

    if (PlatformInfos.isWeb) {
      return _dialogFullScreenWeb(future: future, context: twakeContext);
    } else {
      return _dialogFullScreenMobile(future: future, context: twakeContext);
    }
  }

  static Future<LoadingDialogResult<T>> _dialogFullScreenWeb<T>({
    required Future<T> Function() future,
    required BuildContext context,
  }) async {
    return await showFutureLoadingDialog(
      context: context,
      future: future,
      loadingIcon: LottieBuilder.asset(
        ImagePaths.lottieTwakeLoading,
        width: lottieSizeWeb,
        height: lottieSizeWeb,
      ),
      barrierColor: LinagoraSysColors.material().onPrimary.withOpacity(0.75),
      loadingTitle: L10n.of(context)!.loading,
      loadingTitleStyle: Theme.of(context).textTheme.titleLarge,
      maxWidth: maxWidthLoadingDialogWeb,
      errorTitle: L10n.of(context)!.errorDialogTitle,
      errorTitleStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: LinagoraSysColors.material().onSurfaceVariant,
          ),
      errorDescriptionStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: LinagoraSysColors.material().onSurfaceVariant,
          ),
      errorBackLabel: L10n.of(context)!.cancel,
      errorBackLabelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
      errorNextLabel: L10n.of(context)!.next,
      errorNextLabelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: LinagoraSysColors.material().onPrimary,
          ),
      backgroundErrorDialog: LinagoraSysColors.material().onPrimary,
      backgroundNextLabel: Theme.of(context).colorScheme.primary,
      maxWidthButton: maxWidthDialogButtonMobile,
    );
  }

  static Future<LoadingDialogResult<T>> _dialogFullScreenMobile<T>({
    required Future<T> Function() future,
    required BuildContext context,
  }) async {
    return await showFutureLoadingDialog(
      context: context,
      future: future,
      maxWidth: double.infinity,
      loadingIcon: LottieBuilder.asset(
        ImagePaths.lottieTwakeLoading,
        width: lottieSizeMobile,
        height: lottieSizeMobile,
      ),
      barrierColor: LinagoraSysColors.material().onPrimary.withOpacity(0.75),
      loadingTitle: L10n.of(context)!.loading,
      loadingTitleStyle: Theme.of(context).textTheme.titleMedium,
      errorTitle: L10n.of(context)!.errorDialogTitle,
      errorTitleStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: LinagoraSysColors.material().onSurfaceVariant,
          ),
      errorDescriptionStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: LinagoraSysColors.material().onSurfaceVariant,
          ),
      errorBackLabel: L10n.of(context)!.cancel,
      errorBackLabelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
      errorNextLabel: L10n.of(context)!.next,
      errorNextLabelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: LinagoraSysColors.material().onPrimary,
          ),
      backgroundNextLabel: Theme.of(context).colorScheme.primary,
      backgroundErrorDialog: LinagoraSysColors.material().onPrimary,
      isMobileResponsive: true,
      maxWidthButton: maxWidthDialogButtonMobile,
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
            ImagePaths.lottieTwakeLoading,
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

enum ConfirmResult {
  ok,
  cancel,
}

Future<ConfirmResult> showConfirmAlertDialog({
  required BuildContext context,
  bool useRootNavigator = true,
  bool barrierDismissible = true,
  String? title,
  String? message,
  String? okLabel,
  String? cancelLabel,
  void Function()? onClose,
  Color? okLabelButtonColor,
  Color? cancelLabelButtonColor,
  Color? okTextColor,
  Color? cancelTextColor,
  bool showCloseButton = false,
}) async {
  final result = await showModal<ConfirmResult>(
    context: context,
    configuration: FadeScaleTransitionConfiguration(
      barrierDismissible: barrierDismissible,
    ),
    useRootNavigator: useRootNavigator,
    builder: (context) {
      return ConfirmationDialogBuilder(
        title: title ?? '',
        textContent: message ?? '',
        confirmText: okLabel ?? '',
        cancelText: cancelLabel ?? '',
        confirmLabelButtonColor: okTextColor,
        cancelLabelButtonColor: cancelTextColor,
        confirmBackgroundButtonColor: okLabelButtonColor,
        cancelBackgroundButtonColor: cancelLabelButtonColor,
        onConfirmButtonAction: () {
          Navigator.of(context).pop(ConfirmResult.ok);
          onClose?.call();
        },
        onCancelButtonAction: () {
          Navigator.of(context).pop(ConfirmResult.cancel);
          onClose?.call();
        },
        onCloseButtonAction: () {
          Navigator.of(context).pop(ConfirmResult.cancel);
          onClose?.call();
        },
      );
    },
  );

  return result ?? ConfirmResult.cancel;
}
