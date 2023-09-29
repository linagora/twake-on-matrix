import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_view_web_style.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

class SettingsProfileViewWeb extends StatelessWidget {
  final ValueNotifier<Profile> profileNotifier;
  final String displayName;
  final Widget basicInfoWidget;
  final Widget workIdentitiesInfoWidget;
  final VoidCallback onAvatarTap;

  const SettingsProfileViewWeb({
    super.key,
    required this.profileNotifier,
    required this.displayName,
    required this.basicInfoWidget,
    required this.onAvatarTap,
    required this.workIdentitiesInfoWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: profileNotifier,
      builder: (context, _, __) {
        return Padding(
          padding: SettingsProfileViewWebStyle.paddingBody,
          child: Center(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: SettingsProfileViewWebStyle.bodyWidth,
                    padding: SettingsProfileViewWebStyle.paddingWidgetBasicInfo,
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          SettingsProfileViewWebStyle.radiusCircular,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              SettingsProfileViewWebStyle.paddingBasicInfoTitle,
                          child: Text(
                            L10n.of(context)!.basicInfo,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: SettingsProfileViewWebStyle
                                  .paddingWidgetBasicInfo,
                              child: Stack(
                                alignment: AlignmentDirectional.center,
                                children: [
                                  const SizedBox(
                                    width:
                                        SettingsProfileViewWebStyle.widthSize,
                                  ),
                                  Material(
                                    elevation: Theme.of(context)
                                            .appBarTheme
                                            .scrolledUnderElevation ??
                                        4,
                                    shadowColor: Theme.of(context)
                                        .appBarTheme
                                        .shadowColor,
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                        color: Theme.of(context).dividerColor,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AvatarStyle.defaultSize,
                                      ),
                                    ),
                                    child: Avatar(
                                      mxContent:
                                          profileNotifier.value.avatarUrl,
                                      name: displayName,
                                      size: SettingsProfileViewWebStyle
                                          .avatarSize,
                                      fontSize: SettingsProfileViewWebStyle
                                          .avatarFontSize,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: SettingsProfileViewWebStyle
                                        .positionedBottomSize,
                                    right: SettingsProfileViewWebStyle
                                        .positionedRightSize,
                                    child: InkWell(
                                      onTap: onAvatarTap,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          borderRadius: BorderRadius.circular(
                                            SettingsProfileViewWebStyle
                                                .avatarSize,
                                          ),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                            width: 4,
                                          ),
                                        ),
                                        padding: SettingsProfileViewWebStyle
                                            .paddingEditIcon,
                                        child: Icon(
                                          Icons.edit,
                                          size: SettingsProfileViewWebStyle
                                              .iconEditSize,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: basicInfoWidget,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: SettingsProfileViewWebStyle
                        .paddingWidgetEditProfileInfo,
                    child: Text(
                      L10n.of(context)!.editProfileDescriptions,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: LinagoraRefColors.material().tertiary[30],
                          ),
                    ),
                  ),
                  Container(
                    width: SettingsProfileViewWebStyle.bodyWidth,
                    padding: SettingsProfileViewWebStyle.paddingWidgetBasicInfo,
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          SettingsProfileViewWebStyle.radiusCircular,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              SettingsProfileViewWebStyle.paddingBasicInfoTitle,
                          child: Text(
                            L10n.of(context)!.workIdentitiesInfo,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ),
                        Padding(
                          padding: SettingsProfileViewWebStyle
                              .paddingWorkIdentitiesInfoWidget,
                          child: workIdentitiesInfoWidget,
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: SettingsProfileViewWebStyle
                        .paddingWidgetEditProfileInfo,
                    child: Text(
                      L10n.of(context)!.editWorkIdentitiesDescriptions,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: LinagoraRefColors.material().tertiary[30],
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
