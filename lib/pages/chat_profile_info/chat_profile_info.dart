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
import 'package:fluffychat/presentation/mixins/chat_details_tab_mixin.dart';
import 'package:fluffychat/presentation/mixins/handle_video_download_mixin.dart';
import 'package:fluffychat/presentation/mixins/play_video_action_mixin.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
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

  final ValueNotifier<Either<Failure, Success>> lookupContactNotifier =
      ValueNotifier<Either<Failure, Success>>(
    const Right(LookupContactsInitial()),
  );

  @override
  Room? get room => widget.roomId != null
      ? Matrix.of(context).client.getRoomById(widget.roomId!)
      : null;

  @override
  ChatDetailsScreenEnum get chatType => ChatDetailsScreenEnum.direct;

  final _blockUserInteractor = getIt.get<BlockUserInteractor>();

  final _unblockUserInteractor = getIt.get<UnblockUserInteractor>();

  User? get user =>
      room?.unsafeGetUserFromMemoryOrFallback(room?.directChatMatrixID ?? '');

  bool get isBlockedUser => Matrix.of(context).client.ignoredUsers.contains(
        widget.contact?.matrixId ?? user?.id ?? '',
      );

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
                TwakeDialog.hideLoadingDialog(context);
                TwakeSnackBar.show(
                  context,
                  failure.exception.toString(),
                );
                return;
              }

              if (failure is NoPermissionForUnblockFailure) {
                TwakeDialog.hideLoadingDialog(context);
                TwakeSnackBar.show(
                  context,
                  L10n.of(context)!.permissionErrorUnbanUser,
                );
                return;
              }
            },
            (success) {
              if (success is UnblockUserLoading) {
                TwakeDialog.showLoadingDialog(context);
                return;
              }

              if (success is UnblockUserSuccess) {
                TwakeDialog.hideLoadingDialog(context);
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
                TwakeDialog.hideLoadingDialog(context);
                TwakeSnackBar.show(
                  context,
                  failure.exception.toString(),
                );
                return;
              }

              if (failure is NoPermissionForBlockFailure) {
                TwakeDialog.hideLoadingDialog(context);
                TwakeSnackBar.show(
                  context,
                  L10n.of(context)!.permissionErrorUnbanUser,
                );
                return;
              }
            },
            (success) {
              if (success is BlockUserLoading) {
                TwakeDialog.showLoadingDialog(context);
                return;
              }

              if (success is BlockUserSuccess) {
                TwakeDialog.hideLoadingDialog(context);
                return;
              }
            },
          ),
        );
  }

  @override
  void initState() {
    super.initState();
    lookupMatchContactAction();
  }

  @override
  void dispose() {
    lookupContactNotifier.dispose();
    lookupContactNotifierSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatProfileInfoView(this);
  }
}
