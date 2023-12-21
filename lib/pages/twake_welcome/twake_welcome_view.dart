import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/twake_welcome/twake_welcome.dart';
import 'package:fluffychat/pages/twake_welcome/twake_welcome_view_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:linagora_design_flutter/twake_screen/twake_welcome_screen.dart';

class TwakeWelcomeView extends StatelessWidget {
  final TwakeWelcomeController controller;

  const TwakeWelcomeView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TwakeWelcomeScreen(
      welcomeTo: L10n.of(context)!.welcomeTo,
      welcomeToStyle: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: LinagoraSysColors.material().onSurfaceVariant,
          ),
      descriptionWelcomeTo: L10n.of(context)!.descriptionWelcomeTo,
      descriptionWelcomeToStyle:
          Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: LinagoraSysColors.material().onSurfaceVariant,
              ),
      titleStartMessaging: L10n.of(context)!.startMessaging,
      titleStartMessagingStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: LinagoraSysColors.material().onPrimary,
          ),
      titlePrivacy: L10n.of(context)!.privacy,
      privacyTextStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: LinagoraSysColors.material().primary,
          ),
      logo: SvgPicture.asset(
        ImagePaths.logoTwakeWelcome,
        width: TwakeWelcomeViewStyle.logoWidth,
        height: TwakeWelcomeViewStyle.logoHeight,
      ),
      buttonOnTap: controller.goToTwakeIdScreen,
      privacyOnTap: () =>
          UrlLauncher(context, AppConfig.privacyUrl).openUrlInAppBrowser(),
    );
  }
}
