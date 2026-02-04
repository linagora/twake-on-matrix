import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/user_info/get_user_info_state.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/domain/model/user_info/user_info.dart';
import 'package:fluffychat/pages/chat/optional_selection_area.dart';
import 'package:fluffychat/pages/chat_details/chat_details_view_style.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_action_button.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/add_contact/add_contact_dialog.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact_constant.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/clipboard.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/avatar/round_avatar_style.dart';
import 'package:linagora_design_flutter/extensions/string_extension.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

import 'package:fluffychat/pages/chat_profile_info/chat_profile_info.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_style.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:matrix/matrix.dart' hide Contact;

class ChatProfileInfoView extends StatelessWidget {
  final ChatProfileInfoController controller;

  const ChatProfileInfoView(
    this.controller, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final user = controller.user;
    final contact = controller.presentationContact;
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().surfaceVariant,
      appBar: TwakeAppBar(
        backgroundColor: LinagoraSysColors.material().surfaceVariant,
        title: L10n.of(context)!.contactInfo,
        leading: IconButton(
          onPressed: controller.widget.onBack,
          icon: controller.widget.isInStack
              ? const Icon(
                  Icons.arrow_back_ios,
                )
              : const Icon(Icons.close),
        ),
        context: context,
      ),
      body: NestedScrollView(
        physics: controller.getScrollPhysics(),
        key: controller.nestedScrollViewState,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: _SizedAppBar(
                userInfoNotifier: controller.userInfoNotifier,
                room: controller.room,
                user: user,
                contact: contact,
                isAlreadyInChat: controller.isAlreadyInChat(context),
                builder: (context, height) {
                  return SliverAppBar(
                    backgroundColor:
                        LinagoraSysColors.material().surfaceVariant,
                    toolbarHeight: height,
                    title: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: ChatProfileInfoStyle.maxWidth,
                        maxHeight: height,
                      ),
                      child: Builder(
                        builder: (context) {
                          if (contact?.matrixId != null) {
                            return FutureBuilder(
                              future: Matrix.of(context)
                                  .client
                                  .getProfileFromUserId(
                                    contact!.matrixId!,
                                    getFromRooms: false,
                                  ),
                              builder: (context, snapshot) => _Information(
                                avatarUri: snapshot.data?.avatarUrl,
                                displayName: snapshot.data?.displayName ??
                                    contact.displayName,
                                matrixId: contact.matrixId,
                                userInfoNotifier: controller.userInfoNotifier,
                                isDraftInfo: controller.widget.isDraftInfo,
                                isBlockedUserNotifier: controller.isBlockedUser,
                                onUnblockUser: controller.onUnblockUser,
                                onBlockUser: controller.onBlockUser,
                                isAlreadyInChat:
                                    controller.isAlreadyInChat(context),
                                blockUserLoadingNotifier:
                                    controller.blockUserLoadingNotifier,
                                room: controller.room,
                                onLeaveChat: () => controller.leaveChat(
                                  context,
                                  controller.room,
                                ),
                              ),
                            );
                          }
                          if (contact != null) {
                            return _Information(
                              displayName: contact.displayName,
                              matrixId: contact.matrixId,
                              userInfoNotifier: controller.userInfoNotifier,
                              isDraftInfo: controller.widget.isDraftInfo,
                              isBlockedUserNotifier: controller.isBlockedUser,
                              onUnblockUser: controller.onUnblockUser,
                              onBlockUser: controller.onBlockUser,
                              isAlreadyInChat:
                                  controller.isAlreadyInChat(context),
                              blockUserLoadingNotifier:
                                  controller.blockUserLoadingNotifier,
                              room: controller.room,
                              onLeaveChat: () => controller.leaveChat(
                                context,
                                controller.room,
                              ),
                            );
                          }
                          return _Information(
                            avatarUri: user?.avatarUrl,
                            displayName: user?.calcDisplayname(),
                            matrixId: user?.id,
                            userInfoNotifier: controller.userInfoNotifier,
                            isDraftInfo: controller.widget.isDraftInfo,
                            isBlockedUserNotifier: controller.isBlockedUser,
                            onUnblockUser: controller.onUnblockUser,
                            onBlockUser: controller.onBlockUser,
                            isAlreadyInChat:
                                controller.isAlreadyInChat(context),
                            blockUserLoadingNotifier:
                                controller.blockUserLoadingNotifier,
                            room: controller.room,
                            onLeaveChat: () => controller.leaveChat(
                              context,
                              controller.room,
                            ),
                          );
                        },
                      ),
                    ),
                    automaticallyImplyLeading: false,
                    pinned: true,
                    floating: true,
                    forceElevated: innerBoxIsScrolled,
                    bottom: TabBar(
                      physics: const NeverScrollableScrollPhysics(),
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      indicatorPadding: ChatProfileInfoStyle.indicatorPadding,
                      indicatorWeight: ChatProfileInfoStyle.indicatorWeight,
                      labelStyle:
                          ChatProfileInfoStyle.tabBarLabelStyle(context),
                      unselectedLabelStyle:
                          ChatProfileInfoStyle.tabBarUnselectedLabelStyle(
                        context,
                      ),
                      tabs: controller.tabList.map((page) {
                        return Tab(
                          child: Text(
                            page.getTitle(context),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                          ),
                        );
                      }).toList(),
                      controller: controller.tabController,
                    ),
                  );
                },
              ),
            ),
          ];
        },
        body: ClipRRect(
          borderRadius: BorderRadius.all(
            Radius.circular(
              ChatDetailViewStyle.chatDetailsPageViewWebBorderRadius,
            ),
          ),
          child: Container(
            width: ChatDetailViewStyle.chatDetailsPageViewWebWidth,
            padding: ChatDetailViewStyle.paddingTabBarView,
            decoration: ChatProfileInfoStyle.tabViewDecoration,
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              controller: controller.tabController,
              children: controller.sharedPages().map((page) {
                return page.child;
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _Information extends StatelessWidget {
  const _Information({
    this.avatarUri,
    this.displayName,
    this.matrixId,
    required this.userInfoNotifier,
    required this.isDraftInfo,
    required this.isBlockedUserNotifier,
    this.onUnblockUser,
    this.onBlockUser,
    required this.blockUserLoadingNotifier,
    required this.isAlreadyInChat,
    this.room,
    this.onLeaveChat,
  });

  final Uri? avatarUri;
  final String? displayName;
  final String? matrixId;
  final ValueNotifier<Either<Failure, Success>> userInfoNotifier;
  final bool isDraftInfo;
  final ValueNotifier<bool> isBlockedUserNotifier;
  final void Function()? onUnblockUser;
  final void Function()? onBlockUser;
  final ValueNotifier<bool?> blockUserLoadingNotifier;
  final bool isAlreadyInChat;
  final Room? room;
  final void Function()? onLeaveChat;

  bool canAddContact(Either<Failure, Success> state) {
    if (PlatformInfos.isMobile || matrixId == null) return false;

    final List<Contact> contacts = state.fold(
      (failure) => [],
      (success) => success is GetContactsSuccess ? success.contacts : [],
    );
    return contacts.none((contact) => contact.inTomAddressBook(matrixId!));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: userInfoNotifier,
      builder: (context, userInfo, child) {
        final userInfoModel =
            userInfo.getSuccessOrNull<GetUserInfoSuccess>()?.userInfo;
        return Column(
          children: [
            Stack(
              children: [
                Builder(
                  builder: (context) {
                    final text = displayName?.getShortcutNameForAvatar() ?? '@';
                    final placeholder = Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: text.avatarColors,
                          stops: RoundAvatarStyle.defaultGradientStops,
                        ),
                      ),
                      width: double.infinity,
                      height: ChatProfileInfoStyle.avatarHeight,
                      child: Center(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: ChatProfileInfoStyle.avatarFontSize,
                            color: AvatarStyle.defaultTextColor(true),
                            fontFamily: AvatarStyle.fontFamily,
                            fontWeight: AvatarStyle.fontWeight,
                          ),
                        ),
                      ),
                    );
                    if (avatarUri == null) {
                      return placeholder;
                    }
                    return _buildAvatarWidget(
                      context: context,
                      userInfo: userInfo,
                      userInfoModel: userInfoModel,
                    );
                  },
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: OptionalSelectionArea(
                    isEnabled: PlatformInfos.isWeb,
                    child: _buildDisplayNameWidget(
                      context: context,
                      userInfo: userInfo,
                      userInfoModel: userInfoModel,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: ChatProfileInfoStyle.mainPadding,
              child: Column(
                children: [
                  if (!isAlreadyInChat)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChatProfileActionButton(
                            title: L10n.of(context)!.message,
                            iconData: Icons.messenger_outline_rounded,
                            onTap: () => _handleSendMessageTap(context),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: ChatProfileInfoStyle.copiableContainerPadding,
                    margin: ChatProfileInfoStyle.copiableContainerMargin,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: LinagoraRefColors.material().neutral[90] ??
                            Colors.black,
                      ),
                      borderRadius:
                          ChatProfileInfoStyle.copiableContainerBorderRadius,
                      color: LinagoraSysColors.material().onPrimary,
                    ),
                    child: Column(
                      children: [
                        if (matrixId != null)
                          _CopiableRowWithSvgIcon(
                            iconPath: ImagePaths.icMatrixid,
                            text: matrixId!,
                            title: L10n.of(context)!.username,
                          ),
                        userInfo.fold(
                          (failure) => const SizedBox.shrink(),
                          (success) {
                            if (success is GetUserInfoSuccess) {
                              return Column(
                                children: [
                                  if (success.userInfo.emails?.firstOrNull !=
                                      null) ...{
                                    const SizedBox(
                                      height: ChatProfileInfoStyle.textSpacing,
                                    ),
                                    _CopiableRowWithMaterialIcon(
                                      icon: Icons.alternate_email,
                                      title: L10n.of(context)!.email,
                                      text: success
                                              .userInfo.emails?.firstOrNull ??
                                          '',
                                      enableDivider: true,
                                    ),
                                  },
                                  if (success.userInfo.phones?.firstOrNull !=
                                      null) ...{
                                    const SizedBox(
                                      height: ChatProfileInfoStyle.textSpacing,
                                    ),
                                    _CopiableRowWithMaterialIcon(
                                      icon: Icons.call,
                                      title: L10n.of(context)!.phoneNumber,
                                      text: success
                                              .userInfo.phones?.firstOrNull ??
                                          '',
                                    ),
                                  },
                                ],
                              );
                            }

                            return const SizedBox.shrink();
                          },
                        ),
                        ValueListenableBuilder(
                          valueListenable: getIt
                              .get<ContactsManager>()
                              .getContactsNotifier(),
                          builder: (context, state, child) {
                            return _AddContactButton(
                              canAddContact: canAddContact(state),
                              matrixId: matrixId,
                              displayName: displayName,
                            );
                          },
                        ),
                        if (room?.isDirectChat == true) ...[
                          const SizedBox(
                            height: ChatProfileInfoStyle.textSpacing,
                          ),
                          InkWell(
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            onTap: onLeaveChat,
                            child: _CopiableRowWithMaterialIcon(
                              icon: Icons.logout_outlined,
                              text: L10n.of(context)!.leaveChat,
                              enableCopy: false,
                            ),
                          ),
                        ],
                        const SizedBox(
                          height: ChatProfileInfoStyle.textSpacing,
                        ),
                        ValueListenableBuilder(
                          valueListenable: blockUserLoadingNotifier,
                          builder: (context, isLoading, child) {
                            return ValueListenableBuilder(
                              valueListenable: isBlockedUserNotifier,
                              builder: (context, isBlockedUser, child) {
                                return InkWell(
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  splashColor: Colors.transparent,
                                  onTap: isLoading == true
                                      ? null
                                      : isBlockedUser
                                          ? onUnblockUser
                                          : onBlockUser,
                                  child: _CopiableRowWithSvgIcon(
                                    iconPath: ImagePaths.icFrontHand,
                                    enableCopyIcon: false,
                                    enableDivider: false,
                                    text: isBlockedUser
                                        ? L10n.of(context)!.unblockUser
                                        : L10n.of(context)!.blockUser,
                                    iconColor: isBlockedUser
                                        ? LinagoraSysColors.material().error
                                        : LinagoraSysColors.material().primary,
                                    textColor: isBlockedUser
                                        ? LinagoraSysColors.material().error
                                        : LinagoraSysColors.material().primary,
                                    actionIcon: isLoading == true
                                        ? Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: CupertinoActivityIndicator(
                                              animating: true,
                                              color:
                                                  LinagoraSysColors.material()
                                                      .onSurfaceVariant,
                                            ),
                                          )
                                        : null,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvatarWidget({
    required BuildContext context,
    required Either<Failure, Success> userInfo,
    required UserInfo? userInfoModel,
  }) {
    return userInfo.fold(
      (failure) {
        return Avatar(
          mxContent: avatarUri,
          name: userInfoModel?.displayName ?? displayName,
          size: ChatProfileInfoStyle.avatarHeight,
          sizeWidth: double.infinity,
          isCircle: false,
          fontSize: ChatProfileInfoStyle.avatarFontSize,
        );
      },
      (success) {
        if (success is GettingUserInfo) {
          return SizedBox(
            width: double.infinity,
            height: ChatProfileInfoStyle.avatarHeight,
            child: Center(
              child: CupertinoActivityIndicator(
                animating: true,
                color: LinagoraSysColors.material().onSurfaceVariant,
              ),
            ),
          );
        }
        if (success is GetUserInfoSuccess) {
          return Avatar(
            mxContent: userInfoModel?.avatarUrl != null
                ? Uri.parse(userInfoModel?.avatarUrl ?? '')
                : avatarUri,
            name: userInfoModel?.displayName ?? displayName,
            sizeWidth: double.infinity,
            size: ChatProfileInfoStyle.avatarHeight,
            isCircle: false,
            fontSize: ChatProfileInfoStyle.avatarFontSize,
          );
        }
        return Avatar(
          mxContent: avatarUri,
          name: userInfoModel?.displayName ?? displayName,
          sizeWidth: double.infinity,
          size: ChatProfileInfoStyle.avatarHeight,
          isCircle: false,
          fontSize: ChatProfileInfoStyle.avatarFontSize,
        );
      },
    );
  }

  Widget _buildDisplayNameWidget({
    required BuildContext context,
    required Either<Failure, Success> userInfo,
    required UserInfo? userInfoModel,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
            ),
            child: child,
          ),
        );
      },
      child: userInfo.fold(
        (failure) {
          return Text(
            displayName ?? '',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: LinagoraSysColors.material().onSurface,
                ),
            maxLines: 1,
          );
        },
        (success) {
          if (success is GettingUserInfo) {
            return SizedBox(
              height: Theme.of(context).textTheme.headlineSmall?.height,
            );
          }
          if (success is GetUserInfoSuccess) {
            return Text(
              userInfoModel?.displayName ?? displayName ?? '',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: LinagoraSysColors.material().onSurface,
                  ),
              maxLines: 1,
            );
          }
          return Text(
            displayName ?? '',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: LinagoraSysColors.material().onSurface,
                ),
            maxLines: 1,
          );
        },
      ),
    );
  }

  void _handleSendMessageTap(BuildContext context) {
    if (matrixId == null) return;
    final roomId = Matrix.of(context).client.getDirectChatFromUserId(matrixId!);
    context.pop();
    if (roomId == null) {
      context.go(
        '/rooms/draftChat',
        extra: {
          PresentationContactConstant.receiverId: matrixId ?? '',
          PresentationContactConstant.displayName: displayName ?? '',
          PresentationContactConstant.status: '',
        },
      );
    } else {
      context.go('/rooms/$roomId');
    }
  }
}

class _CopiableRowWithMaterialIcon extends StatelessWidget {
  const _CopiableRowWithMaterialIcon({
    required this.icon,
    required this.text,
    this.title,
    this.enableDivider = true,
    this.enableCopy = true,
  });

  final IconData icon;
  final String text;
  final String? title;
  final bool enableDivider;
  final bool enableCopy;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(ChatProfileInfoStyle.iconPadding),
              child: Icon(
                icon,
                size: ChatProfileInfoStyle.iconSize,
                color: LinagoraSysColors.material().tertiary,
              ),
            ),
            Expanded(
              child: Padding(
                padding: ChatProfileInfoStyle.textPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: LinagoraRefColors.material().neutral[40],
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      text,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: LinagoraSysColors.material().onSurface,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            if (enableCopy)
              IconButton(
                icon: Icon(
                  Icons.content_copy,
                  size: ChatProfileInfoStyle.copyIconSize,
                  color: LinagoraRefColors.material().tertiary[40],
                ),
                color: LinagoraRefColors.material().tertiary[40],
                onPressed: () {
                  TwakeClipboard.instance.copyText(text);
                  TwakeSnackBar.show(
                    context,
                    L10n.of(context)!.copiedToClipboard,
                  );
                },
              ),
          ],
        ),
        if (enableDivider) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 1,
            margin: const EdgeInsets.only(left: 48),
            color: LinagoraStateLayer(
              LinagoraSysColors.material().surfaceTint,
            ).opacityLayer3,
          ),
        ],
      ],
    );
  }
}

class _CopiableRowWithSvgIcon extends StatelessWidget {
  const _CopiableRowWithSvgIcon({
    required this.iconPath,
    required this.text,
    this.title,
    this.textColor,
    this.iconColor,
    this.enableCopyIcon = true,
    this.actionIcon,
    this.enableDivider = true,
  });

  final String iconPath;
  final String text;
  final Color? textColor;
  final Color? iconColor;
  final bool enableCopyIcon;
  final Widget? actionIcon;
  final String? title;
  final bool enableDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(ChatProfileInfoStyle.iconPadding),
              child: SvgPicture.asset(
                iconPath,
                width: ChatProfileInfoStyle.iconSize,
                height: ChatProfileInfoStyle.iconSize,
                colorFilter: ColorFilter.mode(
                  iconColor ?? LinagoraSysColors.material().tertiary,
                  BlendMode.srcIn,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: ChatProfileInfoStyle.textPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: LinagoraRefColors.material().neutral[40],
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      text,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: textColor ??
                                LinagoraSysColors.material().onSurface,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            actionIcon ?? const SizedBox.shrink(),
            if (enableCopyIcon)
              IconButton(
                icon: Icon(
                  Icons.content_copy,
                  size: ChatProfileInfoStyle.copyIconSize,
                  color: LinagoraRefColors.material().tertiary[40],
                ),
                color: LinagoraRefColors.material().tertiary[40],
                focusColor: Theme.of(context).primaryColor,
                onPressed: () {
                  TwakeClipboard.instance.copyText(text);
                  TwakeSnackBar.show(
                    context,
                    L10n.of(context)!.copiedToClipboard,
                  );
                },
              ),
          ],
        ),
        if (enableDivider) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 1,
            margin: const EdgeInsets.only(left: 48),
            color: LinagoraStateLayer(
              LinagoraSysColors.material().surfaceTint,
            ).opacityLayer3,
          ),
        ],
      ],
    );
  }
}

class _SizedAppBar extends StatelessWidget {
  const _SizedAppBar({
    required this.userInfoNotifier,
    required this.user,
    required this.contact,
    required this.isAlreadyInChat,
    required this.builder,
    this.room,
  });

  final ValueNotifier<Either<Failure, Success>> userInfoNotifier;
  final User? user;
  final PresentationContact? contact;
  final bool isAlreadyInChat;
  final Widget Function(BuildContext context, double height) builder;
  final Room? room;

  double getToolbarHeight(
    BuildContext context,
    Either<Failure, Success> userInfoNotifier,
    Either<Failure, Success> getContactState,
  ) {
    final height = userInfoNotifier.fold(
      (failure) => ChatDetailViewStyle.minToolbarHeightSliverAppBar,
      (success) {
        if (success is GettingUserInfo) {
          return ChatDetailViewStyle.mediumToolbarHeightSliverAppBar;
        }
        if (success is GetUserInfoSuccess) {
          if (success.userInfo.emails != null &&
              success.userInfo.phones != null) {
            if (room != null) {
              return ChatDetailViewStyle.maxToolbarHeightSliverAppBar;
            }
            return ChatDetailViewStyle.mediumToolbarHeightSliverAppBar;
          }

          if (success.userInfo.emails != null ||
              success.userInfo.phones != null) {
            return ChatDetailViewStyle.mediumToolbarHeightSliverAppBar;
          }

          return ChatDetailViewStyle.minToolbarHeightSliverAppBar;
        }
        return ChatDetailViewStyle.minToolbarHeightSliverAppBar;
      },
    );

    double additionalHeight = 0;

    if (!isAlreadyInChat) {
      additionalHeight += ChatDetailViewStyle.chatInfoActionHeight;
    }

    final matrixId = contact?.matrixId ?? user?.id;
    final canAddContact = matrixId != null &&
        getContactState.fold(
          (failure) => false,
          (success) => success is GetContactsSuccess
              ? success.contacts.none(
                  (contact) => contact.inTomAddressBook(matrixId),
                )
              : false,
        );
    if (canAddContact) {
      additionalHeight += ChatDetailViewStyle.chatInfoAddContactHeight;
    }

    return height + additionalHeight;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: userInfoNotifier,
      builder: (context, lookupContact, _) {
        return ValueListenableBuilder(
          valueListenable: getIt.get<ContactsManager>().getContactsNotifier(),
          builder: (context, getContactState, child) {
            return builder(
              context,
              getToolbarHeight(context, lookupContact, getContactState),
            );
          },
        );
      },
    );
  }
}

class _AddContactButton extends StatelessWidget {
  const _AddContactButton({
    required this.canAddContact,
    this.matrixId,
    this.displayName,
  });

  final bool canAddContact;
  final String? matrixId;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    if (!canAddContact) {
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.only(
        top: ChatProfileInfoStyle.textSpacing,
      ),
      child: InkWell(
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        focusColor: Colors.transparent,
        splashColor: Colors.transparent,
        onTap: () => showAddContactDialog(
          context,
          matrixId: matrixId,
          displayName: displayName,
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(ChatProfileInfoStyle.iconPadding),
              child: Icon(
                Icons.person_add_outlined,
                size: ChatProfileInfoStyle.iconSize,
                color: LinagoraSysColors.material().primary,
              ),
            ),
            Expanded(
              child: Padding(
                padding: ChatProfileInfoStyle.textPadding,
                child: Text(
                  L10n.of(context)!.addToContacts,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: LinagoraSysColors.material().primary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
