import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_state/get_clients_ui_state.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile_view_mobile_style.dart';
import 'package:fluffychat/presentation/extensions/client_extension.dart';
import 'package:fluffychat/presentation/multiple_account/twake_chat_presentation_account.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/avatar/secondary_avatar.dart';
import 'package:fluffychat/widgets/mixins/popup_menu_widget_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

typedef OnTapMultipleAccountsButton = void Function(
  List<TwakeChatPresentationAccount> multipleAccounts,
);

class SettingsProfileViewMobile extends StatefulWidget {
  final ValueNotifier<Either<Failure, Success>> settingsProfileUIState;
  final OnTapMultipleAccountsButton onTapMultipleAccountsButton;
  final Widget settingsProfileOptions;
  final VoidCallback? onTapAvatar;
  final List<Widget>? menuChildren;
  final MenuController? menuController;
  final ValueNotifier<Either<Failure, Success>> settingsMultiAccountsUIState;
  final Client client;
  final Function(MatrixFile) onImageLoaded;
  final ValueNotifier<Profile?> currentProfile;
  final bool canEditAvatar;
  final AnimationController animationController;
  final VoidCallback onAvatarInfoTap;
  final ValueNotifier<bool> isExpandedAvatar;
  final ResponsiveUtils responsive;

  const SettingsProfileViewMobile({
    super.key,
    required this.settingsProfileOptions,
    required this.currentProfile,
    required this.onTapAvatar,
    required this.settingsProfileUIState,
    required this.client,
    required this.onTapMultipleAccountsButton,
    required this.settingsMultiAccountsUIState,
    required this.onImageLoaded,
    required this.canEditAvatar,
    required this.animationController,
    required this.onAvatarInfoTap,
    required this.isExpandedAvatar,
    this.menuChildren,
    this.menuController,
    required this.responsive,
  });

  @override
  State<SettingsProfileViewMobile> createState() =>
      _SettingsProfileViewMobileState();
}

class _SettingsProfileViewMobileState extends State<SettingsProfileViewMobile> {
  bool isTextSelected = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          children: [
            ValueListenableBuilder(
              valueListenable: widget.isExpandedAvatar,
              builder: (context, isExpanded, _) {
                return AnimatedBuilder(
                  animation: widget.animationController,
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
                            _buildProfileInformation(context),
                          ],
                        ),
                        if (widget.canEditAvatar && !isExpanded)
                          Positioned(
                            bottom: SettingsProfileViewMobileStyle
                                .positionedBottomSize,
                            right: SettingsProfileViewMobileStyle
                                .positionedRightSize,
                            child: MenuAnchor(
                              controller: widget.menuController,
                              style: MenuStyle(
                                padding: const WidgetStatePropertyAll(
                                  EdgeInsets.zero,
                                ),
                                backgroundColor: WidgetStatePropertyAll(
                                  PopupMenuWidgetStyle.defaultMenuColor(
                                    context,
                                  ),
                                ),
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      PopupMenuWidgetStyle.menuBorderRadius,
                                    ),
                                  ),
                                ),
                              ),
                              builder: (
                                BuildContext context,
                                MenuController menuController,
                                Widget? child,
                              ) {
                                return GestureDetector(
                                  onTap: () {
                                    if (PlatformInfos.isWeb) {
                                      menuController.isOpen
                                          ? menuController.close()
                                          : menuController.open();
                                    } else {
                                      widget.onTapAvatar?.call();
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(
                                        SettingsProfileViewMobileStyle
                                            .avatarSize,
                                      ),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        width: SettingsProfileViewMobileStyle
                                            .iconEditBorderWidth,
                                      ),
                                    ),
                                    padding: SettingsProfileViewMobileStyle
                                        .editIconPadding,
                                    child: Icon(
                                      Icons.edit,
                                      size: SettingsProfileViewMobileStyle
                                          .iconEditSize,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                                  ),
                                );
                              },
                              menuChildren: widget.menuChildren ?? [],
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
            Container(
              margin: const EdgeInsets.only(left: 12, right: 12, top: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(
                  Radius.circular(8),
                ),
                border: Border.all(
                  color:
                      LinagoraRefColors.material().neutral[90] ?? Colors.black,
                ),
                color: widget.responsive.isWebDesktop(context)
                    ? Theme.of(context).colorScheme.surface
                    : LinagoraSysColors.material().onPrimary,
              ),
              child: widget.settingsProfileOptions,
            ),
          ],
        ),
        const Expanded(child: SizedBox()),
        if (PlatformInfos.isMobile)
          ValueListenableBuilder(
            valueListenable: widget.settingsMultiAccountsUIState,
            builder: (context, uiState, child) => uiState.fold(
              (failure) => child!,
              (success) {
                if (success is GetClientsLoadingUIState) {
                  return Container(
                    width: double.infinity,
                    height: SettingsProfileViewMobileStyle.bottomButtonHeight,
                    padding: SettingsProfileViewMobileStyle.paddingBottomButton,
                    margin: SettingsProfileViewMobileStyle.marginBottomButton,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        SettingsProfileViewMobileStyle.bottomButtonRadius,
                      ),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.scale(
                          scale: SettingsProfileViewMobileStyle.indicatorScale,
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.onPrimary,
                            strokeWidth: SettingsProfileViewMobileStyle
                                .indicatorStrokeWidth,
                          ),
                        ),
                        SettingsProfileViewMobileStyle.paddingIconAndText,
                        Text(
                          L10n.of(context)!.loadingPleaseWait,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                if (success is GetClientsSuccessUIState) {
                  return InkWell(
                    onTap: () => widget.onTapMultipleAccountsButton.call(
                      success.multipleAccounts,
                    ),
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    child: Container(
                      width: double.infinity,
                      height: SettingsProfileViewMobileStyle.bottomButtonHeight,
                      padding:
                          SettingsProfileViewMobileStyle.paddingBottomButton,
                      margin: SettingsProfileViewMobileStyle.marginBottomButton,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          SettingsProfileViewMobileStyle.bottomButtonRadius,
                        ),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            success.haveMultipleAccounts
                                ? Icons.group_outlined
                                : Icons.person_add_alt_outlined,
                            size: SettingsProfileViewMobileStyle.iconSize,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          SettingsProfileViewMobileStyle.paddingIconAndText,
                          Text(
                            success.haveMultipleAccounts
                                ? L10n.of(context)!.switchAccounts
                                : L10n.of(context)!.addAnotherAccount,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return child!;
              },
            ),
            child: const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildAvatarBackground(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.currentProfile,
      builder: (context, profile, _) {
        final displayName = profile?.displayName ??
            widget.client.mxid(context).localpart ??
            widget.client.mxid(context);
        return SecondaryAvatar(
          animationController: widget.animationController,
          mxContent: profile?.avatarUrl,
          name: displayName,
          fontSize: SettingsProfileViewMobileStyle.avatarFontSize,
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
              alpha: widget.animationController.value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInformation(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.currentProfile,
      builder: (context, profile, _) {
        final displayName = profile?.displayName ??
            widget.client.mxid(context).localpart ??
            widget.client.mxid(context);
        final sysColors = LinagoraSysColors.material();

        return SelectionArea(
          onSelectionChanged: (value) {
            final newSelected = value != null && value.plainText.isNotEmpty;
            if (newSelected != isTextSelected) {
              setState(() => isTextSelected = newSelected);
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!isTextSelected) {
                widget.onAvatarInfoTap.call();
                return;
              }

              FocusScope.of(context).unfocus();
            },
            child: Container(
              height: Tween<double>(
                begin: SettingsProfileViewMobileStyle.minAvatarBackgroundHeight,
                end: SettingsProfileViewMobileStyle.maxAvatarBackgroundHeight,
              ).transform(widget.animationController.value),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(
                    height: SettingsProfileViewMobileStyle.avatarSize,
                    width: SettingsProfileViewMobileStyle.avatarSize,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Tween<Alignment>(
                      begin: Alignment.center,
                      end: Alignment.centerLeft,
                    ).transform(widget.animationController.value),
                    child: Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: ColorTween(
                              begin: sysColors.onSurface,
                              end: sysColors.onPrimary,
                            ).transform(widget.animationController.value),
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
