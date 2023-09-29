import 'package:fluffychat/widgets/twake_app.dart';
import 'package:fluffychat/widgets/twake_toast/twake_toast_widget.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';

class TwakeToast {
  static void show({required String msg}) {
    final FToast fToast = FToast().init(TwakeApp.routerKey.currentContext!);

    fToast.showToast(
      child: TwakeToastWidget(message: msg),
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 2),
      positionedToastBuilder: (context, child) {
        return Positioned(
          bottom: 32.0,
          left: 0,
          right: 0,
          child: child,
        );
      },
    );
  }
}
