import 'package:fluffychat/pages/profile_info/profile_info_page.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ProfileInfoView extends StatelessWidget {
  const ProfileInfoView(
    this.controller, {
    super.key,
    this.onUpdatedMembers,
  });

  final ProfileInfoPageState controller;

  final VoidCallback? onUpdatedMembers;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TwakeAppBar(
        title: L10n.of(context)?.profileInfo ?? "",
        leading: TwakeIconButton(
          paddingAll: 8,
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () => Navigator.of(context).pop(),
          icon: Icons.arrow_back_ios,
        ),
        enableLeftTitle: true,
        centerTitle: true,
        withDivider: true,
        context: context,
      ),
      body: ProfileInfoBody(
        user: controller.user,
        onNewChatOpen: controller.widget.onNewChatOpen,
        onUpdatedMembers: onUpdatedMembers,
      ),
    );
  }
}
