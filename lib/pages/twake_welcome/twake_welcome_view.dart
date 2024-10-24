import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/twake_welcome/twake_welcome.dart';
import 'package:fluffychat/pages/twake_welcome/twake_welcome_view_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class TwakeWelcomeView extends StatelessWidget {
  final TwakeWelcomeController controller;

  const TwakeWelcomeView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TwakeWelcomeScreen(
      appBar: controller.widget.arg?.isAddAnotherAccount == true
          ? AppBar(
              backgroundColor: Colors.transparent,
              leading: TwakeIconButton(
                icon: Icons.chevron_left_outlined,
                onTap: () => context.pop(),
                tooltip: L10n.of(context)!.back,
              ),
              elevation: 0,
            )
          : null,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      signInTitle: AppConfig.isSaasPlatForm ? L10n.of(context)!.signIn : null,
      createTwakeIdTitle:
          AppConfig.isSaasPlatForm ? L10n.of(context)!.createTwakeId : null,
      useCompanyServerTitle: L10n.of(context)!.useYourCompanyServer,
      description: L10n.of(context)!.descriptionTwakeId,
      onUseCompanyServerOnTap: controller.goToHomeserverPicker,
      onSignInOnTap: AppConfig.isSaasPlatForm ? controller.onClickSignIn : null,
      privacyPolicy: L10n.of(context)!.privacyPolicy,
      descriptionPrivacyPolicy: L10n.of(context)!.byContinuingYourAgreeingToOur,
      onPrivacyPolicyOnTap: controller.onClickPrivacyPolicy,
      onCreateTwakeIdOnTap:
          AppConfig.isSaasPlatForm ? controller.onClickCreateTwakeId : null,
      logo: SvgPicture.asset(
        ImagePaths.logoTwakeWelcome,
        width: TwakeWelcomeViewStyle.logoWidth,
        height: TwakeWelcomeViewStyle.logoHeight,
      ),
    );
  }
}
