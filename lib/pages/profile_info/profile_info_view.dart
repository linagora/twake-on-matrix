import 'package:fluffychat/pages/profile_info/profile_info_page.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body.dart';
import 'package:fluffychat/pages/profile_info/profile_info_view_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_state_layer.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

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
      appBar: AppBar(
        backgroundColor: LinagoraSysColors.material().onPrimary,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size(double.infinity, 1),
          child: Container(
            color: LinagoraStateLayer(
              LinagoraSysColors.material().surfaceTint,
            ).opacityLayer1,
            height: 1,
          ),
        ),
        title: Padding(
          padding: ProfileInfoViewStyle.navigationAppBarPadding,
          child: Row(
            children: [
              Padding(
                padding: ProfileInfoViewStyle.backIconPadding,
                child: IconButton(
                  splashColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.chevron_left_outlined,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  L10n.of(context)?.profileInfo ?? "",
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      body: ProfileInfoBody(
        user: controller.user,
        onNewChatOpen: controller.widget.onNewChatOpen,
        onUpdatedMembers: onUpdatedMembers,
      ),
    );
  }
}
