import 'dart:async';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/room/block_user_state.dart';
import 'package:fluffychat/domain/app_state/room/unblock_user_state.dart';
import 'package:fluffychat/domain/app_state/user_info/get_user_info_state.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/domain/usecase/room/block_user_interactor.dart';
import 'package:fluffychat/domain/usecase/room/unblock_user_interactor.dart';
import 'package:fluffychat/domain/usecase/user_info/get_user_info_interactor.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_view.dart';
import 'package:fluffychat/presentation/enum/chat/chat_details_screen_enum.dart';
import 'package:fluffychat/presentation/extensions/client_extension.dart';
import 'package:fluffychat/presentation/extensions/contact/presentation_contact_extension.dart';
import 'package:fluffychat/presentation/mixins/chat_details_tab_mixin.dart';
import 'package:fluffychat/presentation/mixins/handle_video_download_mixin.dart';
import 'package:fluffychat/presentation/mixins/leave_chat_mixin.dart';
import 'package:fluffychat/presentation/mixins/play_video_action_mixin.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/room_status_extension.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

class ChatProfileInfo extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSearch;
  final String? roomId;
  final PresentationContact? contact;
  final bool isInStack;
  final bool isDraftInfo;

  const ChatProfileInfo({
    super.key,
    required this.onBack,
    required this.onSearch,
    required this.isInStack,
    this.roomId,
    this.contact,
    required this.isDraftInfo,
  });

  @override
  State<ChatProfileInfo> createState() => ChatProfileInfoController();
}

class ChatProfileInfoController extends State<ChatProfileInfo>
    with
        HandleVideoDownloadMixin,
        PlayVideoActionMixin,
        TickerProviderStateMixin,
        ChatDetailsTabMixin<ChatProfileInfo>,
        LeaveChatMixin {
  final _getUserInfoInteractor = getIt.get<GetUserInfoInteractor>();

  StreamSubscription? userInfoNotifierSub;

  StreamSubscription? ignoredUsersStreamSub;

  final ValueNotifier<Either<Failure, Success>> userInfoNotifier =
      ValueNotifier<Either<Failure, Success>>(
    Right(GettingUserInfo()),
  );

  final ValueNotifier<bool?> blockUserLoadingNotifier =
      ValueNotifier<bool?>(null);

  final ValueNotifier<bool> isBlockedUser = ValueNotifier<bool>(false);

  @override
  Room? get room => widget.roomId != null
      ? Matrix.read(context).client.getRoomById(widget.roomId!)
      : null;

  @override
  ChatDetailsScreenEnum get chatType => ChatDetailsScreenEnum.direct;

  final _blockUserInteractor = getIt.get<BlockUserInteractor>();

  final _unblockUserInteractor = getIt.get<UnblockUserInteractor>();

  User? get user =>
      room?.unsafeGetUserFromMemoryOrFallback(room?.directChatMatrixID ?? '');

  void getUserInfoAction() {
    userInfoNotifierSub = _getUserInfoInteractor
        .execute(
          userId: presentationContact?.matrixId ?? user?.id ?? '',
        )
        .listen(
          (event) => userInfoNotifier.value = event,
        );
  }

  ScrollPhysics getScrollPhysics() {
    if (tabList.isEmpty) {
      return const NeverScrollableScrollPhysics();
    } else {
      return const ClampingScrollPhysics();
    }
  }

  void onUnblockUser() {
    _unblockUserInteractor
        .execute(
          client: Matrix.of(context).client,
          userId: user?.id ?? presentationContact?.matrixId ?? '',
        )
        .listen(
          (event) => event.fold(
            (failure) {
              if (failure is UnblockUserFailure) {
                blockUserLoadingNotifier.value = false;
                TwakeSnackBar.show(
                  context,
                  failure.exception.toString(),
                );
                return;
              }

              if (failure is NoPermissionForUnblockFailure) {
                blockUserLoadingNotifier.value = false;
                TwakeSnackBar.show(
                  context,
                  L10n.of(context)!.permissionErrorUnblockUser,
                );
                return;
              }

              if (failure is NotValidMxidUnblockFailure) {
                blockUserLoadingNotifier.value = false;
                TwakeSnackBar.show(
                  context,
                  L10n.of(context)!.userIsNotAValidMxid(
                    user?.id ?? presentationContact?.matrixId ?? '',
                  ),
                );
                return;
              }

              if (failure is NotInTheIgnoreListFailure) {
                blockUserLoadingNotifier.value = false;
                TwakeSnackBar.show(
                  context,
                  L10n.of(context)!.userNotFoundInIgnoreList(
                    user?.id ?? presentationContact?.matrixId ?? '',
                  ),
                );
                return;
              }
            },
            (success) {
              if (success is UnblockUserLoading) {
                blockUserLoadingNotifier.value = true;
                return;
              }
            },
          ),
        );
  }

  void onBlockUser() {
    _blockUserInteractor
        .execute(
          client: Matrix.of(context).client,
          userId: user?.id ?? presentationContact?.matrixId ?? '',
        )
        .listen(
          (event) => event.fold(
            (failure) {
              if (failure is BlockUserFailure) {
                blockUserLoadingNotifier.value = false;
                TwakeSnackBar.show(
                  context,
                  failure.exception.toString(),
                );
                return;
              }

              if (failure is NoPermissionForBlockFailure) {
                blockUserLoadingNotifier.value = false;
                TwakeSnackBar.show(
                  context,
                  L10n.of(context)!.permissionErrorBlockUser,
                );
                return;
              }

              if (failure is NotValidMxidBlockFailure) {
                blockUserLoadingNotifier.value = false;
                TwakeSnackBar.show(
                  context,
                  L10n.of(context)!.userIsNotAValidMxid(
                    user?.id ?? presentationContact?.matrixId ?? '',
                  ),
                );
                return;
              }
            },
            (success) {
              if (success is BlockUserLoading) {
                blockUserLoadingNotifier.value = true;
                return;
              }
            },
          ),
        );
  }

  void listenIgnoredUser() {
    isBlockedUser.value = Matrix.read(context)
        .client
        .ignoredUsers
        .contains(presentationContact?.matrixId ?? user?.id ?? '');
    ignoredUsersStreamSub =
        Matrix.read(context).client.ignoredUsersStream.listen((value) {
      final userBlocked = Matrix.read(context)
          .client
          .ignoredUsers
          .contains(presentationContact?.matrixId ?? user?.id ?? '');
      blockUserLoadingNotifier.value = false;
      isBlockedUser.value = userBlocked;
    });
  }

  bool isAlreadyInChat(BuildContext context) {
    if (!PlatformInfos.isMobile) return true;

    final router = GoRouter.of(context);
    final RouteMatch lastMatch =
        router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : router.routerDelegate.currentConfiguration;
    final String location = matchList.uri.toString();
    final pathParameters = matchList.pathParameters;
    return location.contains('/draftChat') || pathParameters['roomid'] != null;
  }

  PresentationContact? presentationContact;

  PresentationContact? _getContactFromId(String matrixId) {
    final getContactsState = getIt.get<ContactsManager>().getContactsNotifier();
    return getContactsState.value.fold(
      (failure) => null,
      (success) => success is GetContactsSuccess
          ? success.contacts
              .firstWhereOrNull(
                (c) => c.emails?.any((e) => e.matrixId == matrixId) == true,
              )
              ?.toPresentationContacts()
              .firstOrNull
          : null,
    );
  }

  void _initPresentationContact() {
    if (widget.contact != null) {
      presentationContact = widget.contact;
      return;
    }

    final matrixId = room?.directChatMatrixID;
    if (matrixId == null) return;
    final contact = _getContactFromId(matrixId);
    if (contact != null) {
      presentationContact = contact;
    }
  }

  void _onTomContactsUpdateListener() {
    final matrixId = presentationContact?.matrixId ?? room?.directChatMatrixID;
    if (matrixId == null) return;
    final updatedContact = _getContactFromId(matrixId);
    if (mounted && updatedContact != null) {
      setState(() {
        presentationContact = updatedContact;
      });
    }
  }

  String? get getLocalizedStatusMessage {
    return room
        ?.getLocalizedStatus(
          context,
          presence: room?.directChatPresence,
        )
        .capitalize(context);
  }

  void handleOnMessage() {
    widget.onBack?.call();
  }

  void handleOnSearch() {
    widget.onBack?.call();
    widget.onSearch?.call();
  }

  @override
  void initState() {
    super.initState();
    _initPresentationContact();
    getIt.get<ContactsManager>().getContactsNotifier().addListener(
          _onTomContactsUpdateListener,
        );
    getUserInfoAction();
    listenIgnoredUser();
  }

  @override
  void dispose() {
    getIt.get<ContactsManager>().getContactsNotifier().removeListener(
          _onTomContactsUpdateListener,
        );
    userInfoNotifier.dispose();
    userInfoNotifierSub?.cancel();
    ignoredUsersStreamSub?.cancel();
    blockUserLoadingNotifier.dispose();
    isBlockedUser.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatProfileInfoView(this);
  }
}
