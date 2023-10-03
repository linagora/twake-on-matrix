import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/material.dart';

class TwakeLoadingDialog {
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
          child: WillPopScope(
            onWillPop: () async => false,
            child: const ProgressDialog(),
          ),
        );
      },
      context: context,
      pageBuilder: (c, a1, a2) {
        return const SizedBox();
      },
    );
  }
}

class ProgressDialog extends StatelessWidget {
  const ProgressDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      content: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircularProgressIndicator.adaptive(),
          ),
          Expanded(
            child: Text(
              'Loading... Please Wait!',
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      ),
    );
  }
}
