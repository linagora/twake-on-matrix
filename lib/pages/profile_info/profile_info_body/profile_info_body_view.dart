import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body_view_style.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_contact_rows.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_header.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class ProfileInfoBodyView extends StatelessWidget {
  const ProfileInfoBodyView({
    required this.controller,
    Key? key,
  }) : super(key: key);
  final ProfileInfoBodyController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: ProfileInfoBodyViewStyle.profileInformationsTopPadding,
          child: Column(
            children: [
              ProfileInfoHeader(controller.user!),
              ProfileInfoContactRows(
                user: controller.user!,
                lookupContactNotifier: controller.lookupContactNotifier,
              ),
            ],
          ),
        ),
        if (!controller.isOwnProfile) ...[
          Divider(
            thickness: ProfileInfoBodyViewStyle.bigDividerThickness,
            color: LinagoraSysColors.material().surface,
          ),
          Padding(
            padding: ProfileInfoBodyViewStyle.newChatButtonPadding,
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => controller.openNewChat(),
                    icon: const Icon(Icons.chat_outlined),
                    label: L10n.of(context)?.newChat != null
                        ? Row(
                            children: [
                              Expanded(
                                child: Text(
                                  L10n.of(context)!.sendMessage,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ] else
          const SizedBox(height: 16),
      ],
    );
  }
}
