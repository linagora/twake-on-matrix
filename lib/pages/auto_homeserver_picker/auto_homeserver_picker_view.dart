import 'package:fluffychat/pages/auto_homeserver_picker/auto_homeserver_picker.dart';
import 'package:fluffychat/pages/auto_homeserver_picker/auto_homeserver_picker_view_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class AutoHomeserverPickerView extends StatelessWidget {
  final AutoHomeserverPickerController controller;
  const AutoHomeserverPickerView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          gradient: LinagoraSysColors.material().linearGradientStartingPage,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  L10n.of(context)!.welcomeTo,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: LinagoraSysColors.material().onSurfaceVariant,
                      ),
                ),
                SvgPicture.asset(
                  ImagePaths.logoTwakeWelcome,
                  width: AutoHomeserverPickerViewStyle.logoWidth,
                  height: AutoHomeserverPickerViewStyle.logoHeight,
                ),
                Padding(
                  padding: AutoHomeserverPickerViewStyle.descriptionPadding,
                  child: Text(
                    L10n.of(context)!.descriptionWelcomeTo,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: LinagoraSysColors.material().onSurfaceVariant,
                        ),
                  ),
                ),
                const SizedBox(height: 32),
                ValueListenableBuilder(
                  valueListenable: controller.showButtonRetryNotifier,
                  builder: (context, isShowRetry, child) {
                    if (isShowRetry) return child!;
                    return const CircularProgressIndicator.adaptive();
                  },
                  child: const SizedBox(),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              child: ValueListenableBuilder(
                valueListenable: controller.showButtonRetryNotifier,
                builder: (context, isShowRetry, child) {
                  if (isShowRetry) return child!;
                  return const SizedBox();
                },
                child: Padding(
                  padding: AutoHomeserverPickerViewStyle.buttonPadding,
                  child: InkWell(
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    onTap: controller.retryCheckHomeserver,
                    child: Container(
                      height: AutoHomeserverPickerViewStyle.buttonHeight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                      ),
                      clipBehavior: Clip.antiAlias,
                      decoration: ShapeDecoration(
                        color: LinagoraSysColors.material().primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AutoHomeserverPickerViewStyle.buttonRadius,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          L10n.of(context)!.startMessaging,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: LinagoraSysColors.material().onPrimary,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
