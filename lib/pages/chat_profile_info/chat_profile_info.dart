import 'dart:async';
import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/lookup_match_contact_state.dart';
import 'package:fluffychat/domain/app_state/room/block_user_state.dart';
import 'package:fluffychat/domain/app_state/room/unblock_user_state.dart';
import 'package:fluffychat/domain/usecase/contacts/lookup_match_contact_interactor.dart';
import 'package:fluffychat/domain/usecase/room/block_user_interactor.dart';
import 'package:fluffychat/domain/usecase/room/unblock_user_interactor.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_view.dart';
import 'package:fluffychat/presentation/enum/chat/chat_details_screen_enum.dart';
import 'package:fluffychat/presentation/extensions/client_extension.dart';
import 'package:fluffychat/presentation/mixins/chat_details_tab_mixin.dart';
import 'package:fluffychat/presentation/mixins/handle_video_download_mixin.dart';
import 'package:fluffychat/presentation/mixins/play_video_action_mixin.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ChatProfileInfo extends StatefulWidget {
  final VoidCallback? onBack;
  final String? roomId;
  final PresentationContact? contact;
  final bool isInStack;
  final bool isDraftInfo;

  const ChatProfileInfo({
    super.key,
    required this.onBack,
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
        SingleTickerProviderStateMixin,
        ChatDetailsTabMixin<ChatProfileInfo> {
  final _lookupMatchContactInteractor =
      getIt.get<LookupMatchContactInteractor>();

  StreamSubscription? lookupContactNotifierSub;

  StreamSubscription? ignoredUsersStreamSub;

  final ValueNotifier<Either<Failure, Success>> lookupContactNotifier =
      ValueNotifier<Either<Failure, Success>>(
    const Right(LookupContactsInitial()),
  );

  final ValueNotifier<bool> blockUserLoadingNotifier =
      ValueNotifier<bool>(false);

  final ValueNotifier<bool> isBlockedUser = ValueNotifier<bool>(false);

  @override
  Room? get room =>
      widget.roomId != null ? client.getRoomById(widget.roomId!) : null;

  @override
  ChatDetailsScreenEnum get chatType => ChatDetailsScreenEnum.direct;

  final _blockUserInteractor = getIt.get<BlockUserInteractor>();

  final _unblockUserInteractor = getIt.get<UnblockUserInteractor>();

  User? get user =>
      room?.unsafeGetUserFromMemoryOrFallback(room?.directChatMatrixID ?? '');

  Client get client => Matrix.read(context).client;

  void lookupMatchContactAction() {
    lookupContactNotifierSub = _lookupMatchContactInteractor
        .execute(
          val: widget.contact?.matrixId ?? user?.id ?? '',
        )
        .listen(
          (event) => lookupContactNotifier.value = event,
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
    if (user == null) return;

    _unblockUserInteractor
        .execute(
          client: Matrix.of(context).client,
          userId: user!.id,
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
                  L10n.of(context)!.permissionErrorUnbanUser,
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
    if (user == null) return;

    _blockUserInteractor
        .execute(
          client: Matrix.of(context).client,
          userId: user!.id,
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
                  L10n.of(context)!.permissionErrorUnbanUser,
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
    isBlockedUser.value = client.ignoredUsers
        .contains(widget.contact?.matrixId ?? user?.id ?? '');
    ignoredUsersStreamSub = client.ignoredUsersStream.listen((value) {
      final userBlocked = client.ignoredUsers
          .contains(widget.contact?.matrixId ?? user?.id ?? '');
      blockUserLoadingNotifier.value = false;
      isBlockedUser.value = userBlocked;
      refreshDataInTabViewInit();
    });
  }

  @override
  void initState() {
    super.initState();
    lookupMatchContactAction();
    listenIgnoredUser();
  }

  @override
  void dispose() {
    lookupContactNotifier.dispose();
    lookupContactNotifierSub?.cancel();
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
