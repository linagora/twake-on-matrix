import 'package:fluffychat/pages/twake_id/twake_id.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class TwakeIdView extends StatelessWidget {
  final TwakeIdController controller;

  const TwakeIdView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TwakeIdScreen(
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      signInTitle: L10n.of(context)!.signIn,
      createTwakeIdTitle: L10n.of(context)!.createTwakeId,
      useCompanyServerTitle: L10n.of(context)!.useYourCompanyServer,
      description: L10n.of(context)!.descriptionTwakeId,
      onUseCompanyServerOnTap: controller.goToHomeserverPicker,
      onSignInOnTap: controller.onClickSignIn,
      backButton: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: TwakeIconButton(
          icon: Icons.arrow_back,
          onTap: () => context.pop(),
          tooltip: L10n.of(context)!.back,
        ),
      ),
    );
  }
}
