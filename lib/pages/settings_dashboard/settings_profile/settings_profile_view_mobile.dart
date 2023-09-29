import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_view_mobile_style.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class SettingsProfileViewMobile extends StatelessWidget {
  final ValueNotifier<Profile> profileNotifier;
  final Widget settingsProfileOptions;
  final VoidCallback onAvatarTap;

  const SettingsProfileViewMobile({
    super.key,
    required this.profileNotifier,
    required this.settingsProfileOptions,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: profileNotifier,
      builder: (context, profile, __) {
        final displayName = profile.displayName ?? profile.userId;
        return Column(
          children: [
            Divider(
              height: SettingsProfileViewMobileStyle.dividerHeight,
              color: LinagoraStateLayer(
                LinagoraSysColors.material().surfaceTint,
              ).opacityLayer3,
            ),
            Padding(
              padding: SettingsProfileViewMobileStyle.padding,
              child: Stack(
                alignment: AlignmentDirectional.center,
                children: [
                  const SizedBox(
                    width: SettingsProfileViewMobileStyle.widthSize,
                  ),
                  Material(
                    elevation:
                        Theme.of(context).appBarTheme.scrolledUnderElevation ??
                            4,
                    shadowColor: Theme.of(context).appBarTheme.shadowColor,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                      borderRadius: BorderRadius.circular(
                        AvatarStyle.defaultSize,
                      ),
                    ),
                    child: Avatar(
                      mxContent: profileNotifier.value.avatarUrl,
                      name: displayName,
                      size: SettingsProfileViewMobileStyle.avatarSize,
                      fontSize: SettingsProfileViewMobileStyle.avatarFontSize,
                    ),
                  ),
                  Positioned(
                    bottom: SettingsProfileViewMobileStyle.positionedBottomSize,
                    right: SettingsProfileViewMobileStyle.positionedRightSize,
                    child: InkWell(
                      onTap: onAvatarTap,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(
                            SettingsProfileViewMobileStyle.avatarSize,
                          ),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onPrimary,
                            width: SettingsProfileViewMobileStyle
                                .iconEditBorderWidth,
                          ),
                        ),
                        padding: SettingsProfileViewMobileStyle.editIconPadding,
                        child: Icon(
                          Icons.edit,
                          size: SettingsProfileViewMobileStyle.iconEditSize,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            settingsProfileOptions,
          ],
        );
      },
    );
  }
}
