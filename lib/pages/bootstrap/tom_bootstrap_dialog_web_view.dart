import 'package:fluffychat/pages/bootstrap/tom_bootstrap_dialog_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:lottie/lottie.dart';

class TomBootstrapDialogWebView extends StatelessWidget {
  final String description;
  const TomBootstrapDialogWebView({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SizedBox(
          height: TomBootstrapDialogStyle.sizedDialogWeb,
          width: TomBootstrapDialogStyle.sizedDialogWeb,
          child: Padding(
            padding: TomBootstrapDialogStyle.paddingDialog,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  L10n.of(context)!.settingUpYourTwake,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: LinagoraSysColors.material().onBackground,
                  ),
                  textAlign: TextAlign.center,
                ),
                Padding(
                  padding: TomBootstrapDialogStyle.lottiePadding,
                  child: LottieBuilder.asset(
                    ImagePaths.lottieTwakeLoading,
                    width: TomBootstrapDialogStyle.lottieSize,
                    height: TomBootstrapDialogStyle.lottieSize,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LinagoraSysColors.material().onBackground,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
