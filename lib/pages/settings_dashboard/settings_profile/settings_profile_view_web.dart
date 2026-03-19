import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_view_web_style.dart';
import 'package:fluffychat/presentation/extensions/client_extension.dart';
import 'package:fluffychat/presentation/model/pick_avatar_state.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:fluffychat/widgets/mixins/popup_menu_widget_style.dart';
import 'package:fluffychat/widgets/stream_image_view.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
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
  final bool canEditAvatar;

  const SettingsProfileViewWeb({
    super.key,
    required this.currentProfile,
    required this.basicInfoWidget,
    required this.workIdentitiesInfoWidget,
    required this.client,
    required this.settingsProfileUIState,
    required this.onImageLoaded,
    required this.canEditAvatar,
    this.menuController,
    this.menuChildren,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Padding(
      padding: SettingsProfileViewWebStyle.paddingBody,
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            children: [
              AvatarAndNameRow(
                settingsProfileUIState: settingsProfileUIState,
                onImageLoaded: onImageLoaded,
                currentProfile: currentProfile,
                client: client,
                canEditAvatar: canEditAvatar,
                menuController: menuController,
                menuChildren: menuChildren,
                basicInfoWidget: basicInfoWidget,
              ),
              Padding(
                padding:
                    SettingsProfileViewWebStyle.paddingWidgetEditProfileInfo,
                child: Text(
                  l10n.editProfileDescriptions,
                  style: textTheme.labelLarge?.copyWith(
                    color: LinagoraRefColors.material().tertiary[30],
                  ),
                ),
              ),
              PersonalInfosColumn(
                workIdentitiesInfoWidget: workIdentitiesInfoWidget,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PersonalInfosColumn extends StatelessWidget {
  const PersonalInfosColumn({
    super.key,
    required this.workIdentitiesInfoWidget,
  });

  final Widget workIdentitiesInfoWidget;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final theme = Theme.of(context);

    return Container(
      width: SettingsProfileViewWebStyle.bodyWidth,
      padding: SettingsProfileViewWebStyle.paddingWidgetBasicInfo,
      clipBehavior: .antiAlias,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: .circular(SettingsProfileViewWebStyle.radiusCircular),
        ),
      ),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Padding(
            padding: SettingsProfileViewWebStyle.paddingBasicInfoTitle,
            child: Text(
              l10n.workIdentitiesInfo,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Padding(
            padding:
                SettingsProfileViewWebStyle.paddingWorkIdentitiesInfoWidget,
            child: workIdentitiesInfoWidget,
          ),
        ],
      ),
    );
  }
}

class AvatarAndNameRow extends StatelessWidget {
  const AvatarAndNameRow({
    super.key,
    required this.settingsProfileUIState,
    required this.onImageLoaded,
    required this.currentProfile,
    required this.client,
    required this.canEditAvatar,
    required this.menuController,
    required this.menuChildren,
    required this.basicInfoWidget,
  });

  final ValueNotifier<Either<Failure, Success>> settingsProfileUIState;
  final Function(MatrixFile) onImageLoaded;
  final ValueNotifier<Profile?> currentProfile;
  final Client client;
  final bool canEditAvatar;
  final MenuController? menuController;
  final List<Widget>? menuChildren;
  final Widget basicInfoWidget;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final theme = Theme.of(context);
    final appBarTheme = theme.appBarTheme;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      width: SettingsProfileViewWebStyle.bodyWidth,
      padding: SettingsProfileViewWebStyle.paddingWidgetBasicInfo,
      clipBehavior: .antiAlias,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: .circular(SettingsProfileViewWebStyle.radiusCircular),
        ),
      ),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Padding(
            padding: SettingsProfileViewWebStyle.paddingBasicInfoTitle,
            child: Text(
              l10n.basicInfo,
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: .start,
            children: [
              Padding(
                padding: SettingsProfileViewWebStyle.paddingWidgetBasicInfo,
                child: Stack(
                  alignment: AlignmentDirectional.center,
                  children: [
                    const SizedBox(
                      width: SettingsProfileViewWebStyle.widthSize,
                    ),
                    ValueListenableBuilder(
                      valueListenable: settingsProfileUIState,
                      builder: (context, uiState, child) => uiState.fold(
                        (failure) => child!,
                        (success) {
                          if (success is GetAvatarOnWebUIStateSuccess) {
                            return ClipOval(
                              child: SizedBox.fromSize(
                                size: const .fromRadius(
                                  SettingsProfileViewWebStyle.radiusImageMemory,
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
                          final displayName =
                              profile?.displayName ??
                              client.mxid(context).localpart ??
                              client.mxid(context);
                          return Material(
                            elevation: appBarTheme.scrolledUnderElevation ?? 4,
                            shadowColor: appBarTheme.shadowColor,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: theme.dividerColor),
                              borderRadius: .circular(AvatarStyle.defaultSize),
                            ),
                            child: Avatar(
                              mxContent: profile?.avatarUrl,
                              name: displayName,
                              size: SettingsProfileViewWebStyle.avatarSize,
                              fontSize:
                                  SettingsProfileViewWebStyle.avatarFontSize,
                            ),
                          );
                        },
                      ),
                    ),
                    if (canEditAvatar)
                      EditMenuBtn(
                        menuController: menuController,
                        menuChildren: menuChildren,
                      ),
                  ],
                ),
              ),
              Expanded(child: basicInfoWidget),
            ],
          ),
        ],
      ),
    );
  }
}

class EditMenuBtn extends StatelessWidget {
  const EditMenuBtn({
    super.key,
    required this.menuController,
    required this.menuChildren,
  });

  final MenuController? menuController;
  final List<Widget>? menuChildren;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      bottom: SettingsProfileViewWebStyle.positionedBottomSize,
      right: SettingsProfileViewWebStyle.positionedRightSize,
      child: MenuAnchor(
        controller: menuController,
        style: MenuStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: .circular(PopupMenuWidgetStyle.menuBorderRadius),
            ),
          ),
          backgroundColor: WidgetStatePropertyAll(
            PopupMenuWidgetStyle.defaultMenuColor(context),
          ),
        ),
        builder: (_, MenuController menuController, _) {
          return GestureDetector(
            onTap: () => menuController.isOpen
                ? menuController.close()
                : menuController.open(),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: .circular(SettingsProfileViewWebStyle.avatarSize),
                border: .all(
                  color: colorScheme.onPrimary,
                  width: SettingsProfileViewWebStyle.iconEditBorderWidth,
                ),
              ),
              padding: SettingsProfileViewWebStyle.paddingEditIcon,
              child: Icon(
                Icons.edit,
                size: SettingsProfileViewWebStyle.iconEditSize,
                color: colorScheme.onPrimary,
              ),
            ),
          );
        },
        menuChildren: menuChildren ?? [],
      ),
    );
  }
}
