import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_view_web_style.dart';
import 'package:fluffychat/presentation/extensions/client_extension.dart';
import 'package:fluffychat/presentation/model/pick_avatar_state.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:fluffychat/widgets/stream_image_view.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

class SettingsProfileViewWeb extends StatelessWidget {
  final ValueNotifier<Either<Failure, Success>> settingsProfileUIState;
  final Widget basicInfoWidget;
  final Widget workIdentitiesInfoWidget;
  final Client client;
  final List<Widget>? menuChildren;
  final MenuController? menuController;
  final Function(MatrixFile) onImageLoaded;
  final ValueNotifier<Profile?> currentProfile;

  const SettingsProfileViewWeb({
    super.key,
    required this.currentProfile,
    required this.basicInfoWidget,
    required this.workIdentitiesInfoWidget,
    required this.client,
    required this.settingsProfileUIState,
    required this.onImageLoaded,
    this.menuController,
    this.menuChildren,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: SettingsProfileViewWebStyle.paddingBody,
      child: Align(
        alignment: Alignment.topCenter,
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
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
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
                                width: SettingsProfileViewWebStyle.widthSize,
                              ),
                              ValueListenableBuilder(
                                valueListenable: settingsProfileUIState,
                                builder: (context, uiState, child) =>
                                    uiState.fold(
                                  (failure) => child!,
                                  (success) {
                                    if (success
                                        is GetAvatarOnWebUIStateSuccess) {
                                      if (success.matrixFile?.readStream ==
                                          null) {
                                        return child!;
                                      }
                                      return ClipOval(
                                        child: SizedBox.fromSize(
                                          size: const Size.fromRadius(
                                            SettingsProfileViewWebStyle
                                                .radiusImageMemory,
                                          ),
                                          child: StreamImageViewer(
                                            matrixFile: success.matrixFile!,
                                            onImageLoaded: onImageLoaded,
                                          ),
                                        ),
                                      );
                                    }
                                    return child!;
                                  },
                                ),
                                child: ValueListenableBuilder(
                                  valueListenable: currentProfile,
                                  builder: (context, profile, _) {
                                    final displayName = profile?.displayName ??
                                        client.mxid(context).localpart ??
                                        client.mxid(context);
                                    return Material(
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
                                        mxContent: profile?.avatarUrl,
                                        name: displayName,
                                        size: SettingsProfileViewWebStyle
                                            .avatarSize,
                                        fontSize: SettingsProfileViewWebStyle
                                            .avatarFontSize,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                bottom: SettingsProfileViewWebStyle
                                    .positionedBottomSize,
                                right: SettingsProfileViewWebStyle
                                    .positionedRightSize,
                                child: MenuAnchor(
                                  controller: menuController,
                                  builder: (
                                    BuildContext context,
                                    MenuController menuController,
                                    Widget? child,
                                  ) {
                                    return GestureDetector(
                                      onTap: () => menuController.isOpen
                                          ? menuController.close()
                                          : menuController.open(),
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
                                            width: SettingsProfileViewWebStyle
                                                .iconEditBorderWidth,
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
                                    );
                                  },
                                  menuChildren: menuChildren ?? [],
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
                padding:
                    SettingsProfileViewWebStyle.paddingWidgetEditProfileInfo,
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
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ),
                    Padding(
                      padding: SettingsProfileViewWebStyle
                          .paddingWorkIdentitiesInfoWidget,
                      child: workIdentitiesInfoWidget,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
