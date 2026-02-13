import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/user_info/get_user_info_state.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/chat_details_page_enum.dart';
import 'package:fluffychat/pages/chat_details/chat_details_view_style.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_app_bar_view.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_style.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class ChatProfileInfoAppBar extends StatefulWidget {
  final ValueNotifier<Either<Failure, Success>> userInfoNotifier;
  final Room? room;
  final User? user;
  final PresentationContact? presentationContact;
  final bool isAlreadyInChat;
  final List<ChatDetailsPage> tabList;
  final TabController? tabController;
  final bool isDraftInfo;
  final Uri? avatarUri;
  final String? displayName;
  final String? matrixId;
  final ValueNotifier<bool> isBlockedUserNotifier;
  final void Function()? onUnblockUser;
  final void Function()? onBlockUser;
  final ValueNotifier<bool?> blockUserLoadingNotifier;
  final void Function(BuildContext context, Room? room)? onLeaveChat;
  final bool innerBoxIsScrolled;
  final String? getLocalizedStatusMessage;
  final VoidCallback onMessage;
  final VoidCallback onSearch;

  const ChatProfileInfoAppBar({
    super.key,
    required this.userInfoNotifier,
    this.room,
    this.user,
    this.presentationContact,
    required this.isDraftInfo,
    required this.tabList,
    this.tabController,
    required this.isAlreadyInChat,
    this.avatarUri,
    this.displayName,
    this.matrixId,
    required this.isBlockedUserNotifier,
    this.onUnblockUser,
    this.onBlockUser,
    required this.blockUserLoadingNotifier,
    this.onLeaveChat,
    required this.innerBoxIsScrolled,
    this.getLocalizedStatusMessage,
    required this.onMessage,
    required this.onSearch,
  });

  @override
  State<ChatProfileInfoAppBar> createState() => _ChatProfileInfoAppBarState();
}

class _ChatProfileInfoAppBarState extends State<ChatProfileInfoAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  static const int _animationDuration = 100;

  ValueNotifier<bool> isExpandedAvatar = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _animationDuration),
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    isExpandedAvatar.dispose();
    super.dispose();
  }

  void _handleGroupInfoTap() {
    if (animationController.isCompleted) {
      animationController.reverse();
      Future.delayed(const Duration(milliseconds: _animationDuration)).then((
        _,
      ) {
        setState(() {
          isExpandedAvatar.value = false;
        });
      });
    } else {
      setState(() {
        isExpandedAvatar.value = true;
      });
      Future.delayed(const Duration(milliseconds: _animationDuration)).then((
        _,
      ) {
        animationController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverOverlapAbsorber(
      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
      sliver: ValueListenableBuilder(
        valueListenable: isExpandedAvatar,
        builder: (context, isExpanded, _) {
          return _SizedAppBar(
            userInfoNotifier: widget.userInfoNotifier,
            room: widget.room,
            user: widget.user,
            contact: widget.presentationContact,
            isAlreadyInChat: widget.isAlreadyInChat,
            builder: (context, height) {
              final totalHeight = isExpanded
                  ? height
                  : height -
                        (ChatProfileInfoStyle.maxAvatarHeight -
                            ChatProfileInfoStyle.toolbarHeightSliverAppBar);
              return SliverAppBar(
                backgroundColor: LinagoraSysColors.material().surfaceVariant,
                toolbarHeight: totalHeight,
                title: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: totalHeight),
                  child: AnimatedBuilder(
                    animation: animationController,
                    builder: (context, _) {
                      final contact = widget.presentationContact;
                      if (contact?.matrixId != null) {
                        return FutureBuilder(
                          future: Matrix.of(context).client
                              .getProfileFromUserId(
                                contact!.matrixId!,
                                getFromRooms: false,
                              ),
                          builder: (context, snapshot) =>
                              ChatProfileInfoAppBarView(
                                groupInfoHeight: ChatProfileInfoStyle
                                    .toolbarHeightSliverAppBar,
                                maxGroupInfoHeight:
                                    ChatProfileInfoStyle.maxAvatarHeight,
                                avatarUri: snapshot.data?.avatarUrl,
                                displayName:
                                    snapshot.data?.displayName ??
                                    contact.displayName,
                                matrixId: contact.matrixId,
                                userInfoNotifier: widget.userInfoNotifier,
                                isDraftInfo: widget.isDraftInfo,
                                isBlockedUserNotifier:
                                    widget.isBlockedUserNotifier,
                                onUnblockUser: widget.onUnblockUser,
                                onBlockUser: widget.onBlockUser,
                                isAlreadyInChat: widget.isAlreadyInChat,
                                blockUserLoadingNotifier:
                                    widget.blockUserLoadingNotifier,
                                room: widget.room,
                                onLeaveChat: () => widget.onLeaveChat?.call(
                                  context,
                                  widget.room,
                                ),
                                onChatInfoTap: _handleGroupInfoTap,
                                animationController: animationController,
                                getLocalizedStatusMessage:
                                    widget.getLocalizedStatusMessage,
                                onSearch: widget.onSearch,
                                onMessage: widget.onMessage,
                              ),
                        );
                      }
                      if (contact != null) {
                        return ChatProfileInfoAppBarView(
                          groupInfoHeight:
                              ChatProfileInfoStyle.toolbarHeightSliverAppBar,
                          maxGroupInfoHeight:
                              ChatProfileInfoStyle.maxAvatarHeight,
                          displayName: contact.displayName,
                          matrixId: contact.matrixId,
                          userInfoNotifier: widget.userInfoNotifier,
                          isDraftInfo: widget.isDraftInfo,
                          isBlockedUserNotifier: widget.isBlockedUserNotifier,
                          onUnblockUser: widget.onUnblockUser,
                          onBlockUser: widget.onBlockUser,
                          isAlreadyInChat: widget.isAlreadyInChat,
                          blockUserLoadingNotifier:
                              widget.blockUserLoadingNotifier,
                          room: widget.room,
                          onLeaveChat: () =>
                              widget.onLeaveChat?.call(context, widget.room),
                          onChatInfoTap: _handleGroupInfoTap,
                          animationController: animationController,
                          avatarUri: widget.avatarUri,
                          getLocalizedStatusMessage:
                              widget.getLocalizedStatusMessage,
                          onSearch: widget.onSearch,
                          onMessage: widget.onMessage,
                        );
                      }
                      return ChatProfileInfoAppBarView(
                        groupInfoHeight:
                            ChatProfileInfoStyle.toolbarHeightSliverAppBar,
                        maxGroupInfoHeight:
                            ChatProfileInfoStyle.maxAvatarHeight,
                        avatarUri: widget.user?.avatarUrl,
                        displayName: widget.user?.calcDisplayname(),
                        matrixId: widget.user?.id,
                        userInfoNotifier: widget.userInfoNotifier,
                        isDraftInfo: widget.isDraftInfo,
                        isBlockedUserNotifier: widget.isBlockedUserNotifier,
                        onUnblockUser: widget.onUnblockUser,
                        onBlockUser: widget.onBlockUser,
                        isAlreadyInChat: widget.isAlreadyInChat,
                        blockUserLoadingNotifier:
                            widget.blockUserLoadingNotifier,
                        room: widget.room,
                        onLeaveChat: () =>
                            widget.onLeaveChat?.call(context, widget.room),
                        onChatInfoTap: _handleGroupInfoTap,
                        animationController: animationController,
                        getLocalizedStatusMessage:
                            widget.getLocalizedStatusMessage,
                        onSearch: widget.onSearch,
                        onMessage: widget.onMessage,
                      );
                    },
                  ),
                ),
                automaticallyImplyLeading: false,
                pinned: true,
                floating: true,
                forceElevated: widget.innerBoxIsScrolled,
                bottom: TabBar(
                  physics: const NeverScrollableScrollPhysics(),
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  indicatorPadding: ChatProfileInfoStyle.indicatorPadding,
                  indicatorWeight: ChatProfileInfoStyle.indicatorWeight,
                  labelStyle: ChatProfileInfoStyle.tabBarLabelStyle(context),
                  unselectedLabelStyle:
                      ChatProfileInfoStyle.tabBarUnselectedLabelStyle(context),
                  tabs: widget.tabList.map((page) {
                    return Tab(
                      child: Text(
                        page.getTitle(context),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                      ),
                    );
                  }).toList(),
                  controller: widget.tabController,
                ),
              );
            },
          );
        },
      ),
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
            return getIt.get<ResponsiveUtils>().isMobile(context)
                ? ChatDetailViewStyle.minToolbarHeightSliverAppBar
                : ChatDetailViewStyle.mediumToolbarHeightSliverAppBar;
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
    final canAddContact =
        matrixId != null &&
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
