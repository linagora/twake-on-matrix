import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/user_info/get_user_info_state.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_action_button.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_style.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/add_contact/add_contact_dialog.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact_constant.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/clipboard.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart' hide Contact;

class ChatProfileInfoDetails extends StatelessWidget {
  const ChatProfileInfoDetails({
    super.key,
    this.displayName,
    this.matrixId,
    required this.userInfoNotifier,
    required this.isBlockedUserNotifier,
    this.onUnblockUser,
    this.onBlockUser,
    required this.blockUserLoadingNotifier,
    required this.isAlreadyInChat,
    this.room,
    this.onLeaveChat,
  });

  final String? displayName;
  final String? matrixId;
  final ValueNotifier<Either<Failure, Success>> userInfoNotifier;
  final ValueNotifier<bool> isBlockedUserNotifier;
  final void Function()? onUnblockUser;
  final void Function()? onBlockUser;
  final ValueNotifier<bool?> blockUserLoadingNotifier;
  final bool isAlreadyInChat;
  final Room? room;
  final void Function()? onLeaveChat;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                color: LinagoraRefColors.material().neutral[90] ?? Colors.black,
              ),
              borderRadius: ChatProfileInfoStyle.copiableContainerBorderRadius,
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
                userInfoNotifier.value.fold(
                  (failure) => const SizedBox.shrink(),
                  (success) {
                    if (success is GetUserInfoSuccess) {
                      return Column(
                        children: [
                          if (success.userInfo.emails?.firstOrNull != null) ...{
                            const SizedBox(
                              height: ChatProfileInfoStyle.textSpacing,
                            ),
                            _CopiableRowWithMaterialIcon(
                              icon: Icons.alternate_email,
                              title: L10n.of(context)!.email,
                              text: success.userInfo.emails?.firstOrNull ?? '',
                              enableDivider: true,
                            ),
                          },
                          if (success.userInfo.phones?.firstOrNull != null) ...{
                            const SizedBox(
                              height: ChatProfileInfoStyle.textSpacing,
                            ),
                            _CopiableRowWithMaterialIcon(
                              icon: Icons.call,
                              title: L10n.of(context)!.phoneNumber,
                              text: success.userInfo.phones?.firstOrNull ?? '',
                            ),
                          },
                        ],
                      );
                    }

                    return const SizedBox.shrink();
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
    );
  }

  bool canAddContact(Either<Failure, Success> state) {
    if (PlatformInfos.isMobile || matrixId == null) return false;

    final List<Contact> contacts = state.fold(
      (failure) => [],
      (success) => success is GetContactsSuccess ? success.contacts : [],
    );
    return contacts.none((contact) => contact.inTomAddressBook(matrixId!));
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
    this.iconColor,
    required this.text,
    this.title,
    this.enableDivider = true,
    this.enableCopy = true,
    this.textStyle,
  });

  final IconData icon;
  final Color? iconColor;
  final String text;
  final TextStyle? textStyle;
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
                color: iconColor ?? LinagoraSysColors.material().tertiary,
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
                      style: textStyle ??
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
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
        child: _CopiableRowWithMaterialIcon(
          icon: Icons.person_add_outlined,
          iconColor: LinagoraSysColors.material().primary,
          text: L10n.of(context)!.addToContacts,
          textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: LinagoraSysColors.material().primary,
              ),
          enableCopy: false,
        ),
      ),
    );
  }
}
