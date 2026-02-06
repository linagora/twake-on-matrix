import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body_view_style.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_contact_rows.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_header.dart';
import 'package:fluffychat/widgets/avatar/secondary_avatar.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

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
        if (controller.responsive.isMobile(context))
          _buildMobileHeader(context)
        else
          _buildWebHeader(context),
        const SizedBox(height: 16),
        ProfileInfoContactRows(
          user: controller.user!,
          userInfoNotifier: controller.userInfoNotifier,
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

  Widget _buildMobileHeader(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.isExpandedAvatar,
      builder: (context, isExpanded, _) {
        return AnimatedBuilder(
          animation: controller.animationController,
          builder: (context, _) {
            return Stack(
              children: [
                Positioned.fill(
                  child: _buildAvatarBackground(context),
                ),
                Positioned.fill(
                  child: _buildGradientOverlay(context),
                ),
                Column(
                  children: [
                    ProfileInfoHeader(
                      user: controller.user!,
                      userInfoNotifier: controller.userInfoNotifier,
                      animationController: controller.animationController,
                      onAvatarInfoTap: controller.onAvatarInfoTap,
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWebHeader(BuildContext context) {
    return ProfileInfoHeader(
      user: controller.user!,
      userInfoNotifier: controller.userInfoNotifier,
      animationController: controller.animationController,
      onAvatarInfoTap: controller.onAvatarInfoTap,
    );
  }

  Widget _buildAvatarBackground(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.userInfoNotifier,
      builder: (context, userInfo, _) {
        final displayName = controller.user?.calcDisplayname() ?? '';
        final avatarUrl = controller.user?.avatarUrl;

        return SecondaryAvatar(
          animationController: controller.animationController,
          mxContent: avatarUrl,
          name: displayName,
          fontSize: ProfileInfoBodyViewStyle.avatarFontSize,
        );
      },
    );
  }

  Widget _buildGradientOverlay(BuildContext context) {
    final sysColor = LinagoraSysColors.material();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            sysColor.onTertiaryContainer.withValues(
              alpha: controller.animationController.value,
            ),
          ],
        ),
      ),
    );
  }
}
