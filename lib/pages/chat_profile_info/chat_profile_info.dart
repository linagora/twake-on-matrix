import 'dart:async';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/contact/get_contacts_state.dart';
import 'package:twake_chat/domain/app_state/room/block_user_state.dart';
import 'package:twake_chat/domain/app_state/room/unblock_user_state.dart';
import 'package:twake_chat/domain/app_state/user_info/get_user_info_state.dart';
import 'package:twake_chat/domain/contact_manager/contacts_manager.dart';
import 'package:twake_chat/domain/usecase/room/block_user_interactor.dart';
import 'package:twake_chat/domain/usecase/room/unblock_user_interactor.dart';
import 'package:twake_chat/domain/usecase/user_info/get_user_info_interactor.dart';
import 'package:twake_chat/pages/chat_profile_info/chat_profile_info_view.dart';
import 'package:twake_chat/presentation/enum/chat/chat_details_screen_enum.dart';
import 'package:twake_chat/presentation/extensions/client_extension.dart';
import 'package:twake_chat/presentation/extensions/contact/presentation_contact_extension.dart';
import 'package:twake_chat/presentation/mixins/chat_details_tab_mixin.dart';
import 'package:twake_chat/presentation/mixins/handle_video_download_mixin.dart';
import 'package:twake_chat/presentation/mixins/leave_chat_mixin.dart';
import 'package:twake_chat/presentation/mixins/play_video_action_mixin.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact_constant.dart';
import 'package:twake_chat/utils/room_status_extension.dart';
import 'package:twake_chat/utils/string_extension.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

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
      ValueNotifier<Either<Failure, Success>>(Right(GettingUserInfo()));

  final ValueNotifier<bool?> blockUserLoadingNotifier = ValueNotifier<bool?>(
    null,
  );

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
        .execute(userId: presentationContact?.matrixId ?? user?.id ?? '')
        .listen((event) => userInfoNotifier.value = event);
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
                TwakeSnackBar.show(context, failure.exception.toString());
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
                TwakeSnackBar.show(context, failure.exception.toString());
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
    isBlockedUser.value = Matrix.read(context).client.ignoredUsers.contains(
      presentationContact?.matrixId ?? user?.id ?? '',
    );
    ignoredUsersStreamSub = Matrix.read(context).client.ignoredUsersStream
        .listen((value) {
          final userBlocked = Matrix.read(context).client.ignoredUsers.contains(
            presentationContact?.matrixId ?? user?.id ?? '',
          );
          blockUserLoadingNotifier.value = false;
          isBlockedUser.value = userBlocked;
        });
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
        ?.getLocalizedStatus(context, presence: room?.directChatPresence)
        .capitalize(context);
  }

  void handleOnMessage() {
    if (!PlatformInfos.isMobile) {
      widget.onBack?.call();
      return;
    }

    final matrixId = presentationContact?.matrixId ?? user?.id;
    if (matrixId == null) return;
    final roomId = Matrix.of(context).client.getDirectChatFromUserId(matrixId);

    if (roomId == null) {
      final extra = {
        PresentationContactConstant.receiverId: matrixId,
        PresentationContactConstant.displayName:
            presentationContact?.displayName ?? user?.calcDisplayname() ?? '',
        PresentationContactConstant.status: '',
      };
      context.pop();
      context.go(DraftChatRoute($extra: extra).location, extra: extra);
    } else {
      Navigator.of(context).popUntil(
        (route) => route.settings.name == '${RoomRoute.pathPrefix}$roomId',
      );
      RoomRoute(roomid: roomId).go(context);
    }
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
