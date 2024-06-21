import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body_view_style.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_contact_rows.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_header.dart';
import 'package:flutter/material.dart';

class ProfileInfoBodyView extends StatelessWidget {
  const ProfileInfoBodyView({
    required this.controller,
    super.key,
  });
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
          Padding(
            padding: ProfileInfoBodyViewStyle.actionsPadding,
            child: controller.buildProfileInfoActions(context),
          ),
        ] else
          const SizedBox(height: 16),
      ],
    );
  }
}
