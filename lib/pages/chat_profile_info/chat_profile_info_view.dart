import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/contact/lookup_match_contact_state.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
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
import 'package:matrix/matrix.dart';

class ChatProfileInfoView extends StatelessWidget {
  final ChatProfileInfoController controller;

  const ChatProfileInfoView(
    this.controller, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final user = controller.user;
    final contact = controller.widget.contact;
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().surfaceVariant,
      appBar: TwakeAppBar(
        backgroundColor: LinagoraSysColors.material().surfaceVariant,
        title: L10n.of(context)!.contactInfo,
        leading: IconButton(
          onPressed: controller.widget.onBack,
          icon: controller.widget.isInStack
              ? const Icon(
                  Icons.chevron_left_outlined,
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
                lookupContactNotifier: controller.lookupContactNotifier,
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
                                lookupContactNotifier:
                                    controller.lookupContactNotifier,
                                isDraftInfo: controller.widget.isDraftInfo,
                                isBlockedUserNotifier: controller.isBlockedUser,
                                onUnblockUser: controller.onUnblockUser,
                                onBlockUser: controller.onBlockUser,
                                isAlreadyInChat:
                                    controller.isAlreadyInChat(context),
                                blockUserLoadingNotifier:
                                    controller.blockUserLoadingNotifier,
                              ),
                            );
                          }
                          if (contact != null) {
                            return _Information(
                              displayName: contact.displayName,
                              matrixId: contact.matrixId,
                              lookupContactNotifier:
                                  controller.lookupContactNotifier,
                              isDraftInfo: controller.widget.isDraftInfo,
                              isBlockedUserNotifier: controller.isBlockedUser,
                              onUnblockUser: controller.onUnblockUser,
                              onBlockUser: controller.onBlockUser,
                              isAlreadyInChat:
                                  controller.isAlreadyInChat(context),
                              blockUserLoadingNotifier:
                                  controller.blockUserLoadingNotifier,
                            );
                          }
                          return _Information(
                            avatarUri: user?.avatarUrl,
                            displayName: user?.calcDisplayname(),
                            matrixId: user?.id,
                            lookupContactNotifier:
                                controller.lookupContactNotifier,
                            isDraftInfo: controller.widget.isDraftInfo,
                            isBlockedUserNotifier: controller.isBlockedUser,
                            onUnblockUser: controller.onUnblockUser,
                            onBlockUser: controller.onBlockUser,
                            isAlreadyInChat:
                                controller.isAlreadyInChat(context),
                            blockUserLoadingNotifier:
                                controller.blockUserLoadingNotifier,
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
    required this.lookupContactNotifier,
    required this.isDraftInfo,
    required this.isBlockedUserNotifier,
    this.onUnblockUser,
    this.onBlockUser,
    required this.blockUserLoadingNotifier,
    required this.isAlreadyInChat,
  });

  final Uri? avatarUri;
  final String? displayName;
  final String? matrixId;
  final ValueNotifier<Either<Failure, Success>> lookupContactNotifier;
  final bool isDraftInfo;
  final ValueNotifier<bool> isBlockedUserNotifier;
  final void Function()? onUnblockUser;
  final void Function()? onBlockUser;
  final ValueNotifier<bool?> blockUserLoadingNotifier;
  final bool isAlreadyInChat;

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
    return Column(
      children: [
        Padding(
          padding: ChatProfileInfoStyle.mainPadding,
          child: LayoutBuilder(
            builder: (context, constraints) => Builder(
              builder: (context) {
                final text = displayName?.getShortcutNameForAvatar() ?? '@';
                final placeholder = Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: text.avatarColors,
                      stops: RoundAvatarStyle.defaultGradientStops,
                    ),
                  ),
                  width: ChatProfileInfoStyle.avatarSize,
                  height: ChatProfileInfoStyle.avatarSize,
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
                return Avatar(
                  mxContent: avatarUri,
                  name: displayName,
                  size: ChatProfileInfoStyle.avatarSize,
                  fontSize: ChatProfileInfoStyle.avatarFontSize,
                );
              },
            ),
          ),
        ),
        Padding(
          padding: ChatProfileInfoStyle.mainPadding,
          child: Column(
            children: [
              Text(
                displayName ?? '',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: LinagoraSysColors.material().onSurface,
                    ),
                maxLines: 1,
              ),
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
                      ),
                    ValueListenableBuilder(
                      valueListenable: lookupContactNotifier,
                      builder: (context, contact, child) {
                        return contact.fold(
                          (failure) => const SizedBox.shrink(),
                          (success) {
                            if (success is LookupMatchContactSuccess) {
                              return Column(
                                children: [
                                  if (success.contact.emails != null) ...{
                                    const SizedBox(
                                      height: ChatProfileInfoStyle.textSpacing,
                                    ),
                                    _CopiableRowWithMaterialIcon(
                                      icon: Icons.alternate_email,
                                      text: success
                                              .contact.emails?.first.address ??
                                          '',
                                    ),
                                  },
                                  if (success.contact.phoneNumbers != null) ...{
                                    const SizedBox(
                                      height: ChatProfileInfoStyle.textSpacing,
                                    ),
                                    _CopiableRowWithMaterialIcon(
                                      icon: Icons.call,
                                      text: success.contact.phoneNumbers?.first
                                              .number ??
                                          '',
                                    ),
                                  },
                                ],
                              );
                            }

                            return const SizedBox.shrink();
                          },
                        );
                      },
                      child: const SizedBox.shrink(),
                    ),
                    ValueListenableBuilder(
                      valueListenable:
                          getIt.get<ContactsManager>().getContactsNotifier(),
                      builder: (context, state, child) {
                        return _AddContactButton(
                          canAddContact: canAddContact(state),
                          matrixId: matrixId,
                          displayName: displayName,
                        );
                      },
                    ),
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
                                          color: LinagoraSysColors.material()
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
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(ChatProfileInfoStyle.iconPadding),
          child: Icon(
            icon,
            size: ChatProfileInfoStyle.iconSize,
            color: LinagoraSysColors.material().onSurface,
          ),
        ),
        Expanded(
          child: Padding(
            padding: ChatProfileInfoStyle.textPadding,
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: LinagoraSysColors.material().onSurface,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.content_copy,
            size: ChatProfileInfoStyle.copyIconSize,
            color: LinagoraRefColors.material().tertiary[40],
          ),
          color: LinagoraRefColors.material().tertiary[40],
          onPressed: () {
            TwakeClipboard.instance.copyText(text);
            TwakeSnackBar.show(context, L10n.of(context)!.copiedToClipboard);
          },
        ),
      ],
    );
  }
}

class _CopiableRowWithSvgIcon extends StatelessWidget {
  const _CopiableRowWithSvgIcon({
    required this.iconPath,
    required this.text,
    this.textColor,
    this.iconColor,
    this.enableCopyIcon = true,
    this.actionIcon,
  });

  final String iconPath;
  final String text;
  final Color? textColor;
  final Color? iconColor;
  final bool enableCopyIcon;
  final Widget? actionIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(ChatProfileInfoStyle.iconPadding),
          child: SvgPicture.asset(
            iconPath,
            width: ChatProfileInfoStyle.iconSize,
            height: ChatProfileInfoStyle.iconSize,
            colorFilter: ColorFilter.mode(
              iconColor ?? LinagoraSysColors.material().onSurface,
              BlendMode.srcIn,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: ChatProfileInfoStyle.textPadding,
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: textColor ?? LinagoraSysColors.material().onSurface,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
              TwakeSnackBar.show(context, L10n.of(context)!.copiedToClipboard);
            },
          ),
      ],
    );
  }
}

class _SizedAppBar extends StatelessWidget {
  const _SizedAppBar({
    required this.lookupContactNotifier,
    required this.user,
    required this.contact,
    required this.isAlreadyInChat,
    required this.builder,
  });

  final ValueNotifier<Either<Failure, Success>> lookupContactNotifier;
  final User? user;
  final PresentationContact? contact;
  final bool isAlreadyInChat;
  final Widget Function(BuildContext context, double height) builder;

  double getToolbarHeight(
    BuildContext context,
    Either<Failure, Success> lookupContact,
    Either<Failure, Success> getContactState,
  ) {
    final height = lookupContact.fold(
      (failure) => ChatDetailViewStyle.minToolbarHeightSliverAppBar,
      (success) {
        if (success is LookupContactsLoading) {
          return ChatDetailViewStyle.mediumToolbarHeightSliverAppBar;
        }
        if (success is LookupMatchContactSuccess) {
          if (success.contact.emails != null &&
              success.contact.phoneNumbers != null) {
            return ChatDetailViewStyle.maxToolbarHeightSliverAppBar;
          }

          if (success.contact.emails != null ||
              success.contact.phoneNumbers != null) {
            return ChatDetailViewStyle.mediumToolbarHeightSliverAppBar;
          }

          return ChatDetailViewStyle.maxToolbarHeightSliverAppBar;
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
      valueListenable: lookupContactNotifier,
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
