import 'package:fluffychat/pages/twake_welcome/twake_welcome.dart';
import 'package:fluffychat/pages/twake_welcome/twake_welcome_view_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class TwakeWelcomeView extends StatelessWidget {
  final TwakeWelcomeController controller;

  const TwakeWelcomeView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TwakeWelcomeScreen(
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      useCompanyServerTitle: L10n.of(context)!.useYourCompanyServer,
      description: L10n.of(context)!.descriptionTwakeId,
      onUseCompanyServerOnTap: controller.goToHomeserverPicker,
      logo: SvgPicture.asset(
        ImagePaths.logoTwakeWelcome,
        width: TwakeWelcomeViewStyle.logoWidth,
        height: TwakeWelcomeViewStyle.logoHeight,
      ),
    );
  }
}
