import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/set_permission_level_state.dart';
import 'package:fluffychat/domain/app_state/user_info/get_user_info_state.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/domain/usecase/room/set_permission_level_interactor.dart';
import 'package:fluffychat/domain/usecase/user_info/get_user_info_interactor.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body_view.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body_view_style.dart';
import 'package:fluffychat/presentation/enum/profile_info/profile_info_body_enum.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact_constant.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/dialog/warning_dialog.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/utils/user_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class ProfileInfoBody extends StatefulWidget {
  const ProfileInfoBody({
    required this.user,
    this.onNewChatOpen,
    this.onUpdatedMembers,
    this.onTransferOwnershipSuccess,
    super.key,
  });

  final User? user;

  final VoidCallback? onNewChatOpen;

  final VoidCallback? onUpdatedMembers;

  final VoidCallback? onTransferOwnershipSuccess;

  @override
  State<ProfileInfoBody> createState() => ProfileInfoBodyController();
}

class ProfileInfoBodyController extends State<ProfileInfoBody>
    with SingleTickerProviderStateMixin {
  static const int _animationDuration = 100;

  final ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  StreamSubscription? _setPermissionLevelSubscription;

  StreamSubscription? userInfoNotifierSub;

  final ValueNotifier<Either<Failure, Success>> userInfoNotifier =
      ValueNotifier<Either<Failure, Success>>(Right(GettingUserInfo()));

  late AnimationController animationController;

  final ValueNotifier<bool> isExpandedAvatar = ValueNotifier<bool>(false);

  Timer? _avatarToggleTimer;

  User? get user => widget.user;

  bool get isOwnProfile => user?.id == user?.room.client.userID;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _animationDuration),
    );
    getUserInfoAction();
  }

  @override
  void dispose() {
    userInfoNotifierSub?.cancel();
    _setPermissionLevelSubscription?.cancel();
    _avatarToggleTimer?.cancel();
    animationController.dispose();
    isExpandedAvatar.dispose();
    userInfoNotifier.dispose();
    super.dispose();
  }

  void getUserInfoAction() {
    if (user == null) return;
    userInfoNotifierSub = getIt
        .get<GetUserInfoInteractor>()
        .execute(userId: user!.id)
        .listen((event) => userInfoNotifier.value = event);
  }

  void openNewChat() {
    if (user == null) return;
    final roomId = Matrix.of(context).client.getDirectChatFromUserId(user!.id);

    if (roomId == null) {
      if (!PlatformInfos.isMobile && widget.onNewChatOpen != null) {
        widget.onNewChatOpen!();
      }

      _goToDraftChat(
        context: context,
        path: "rooms",
        contactPresentationSearch: user!.toContactPresentationSearch(),
      );
    } else {
      if (PlatformInfos.isMobile) {
        Navigator.of(
          context,
        ).popUntil((route) => route.settings.name == "/rooms/room");
      } else {
        if (widget.onNewChatOpen != null) widget.onNewChatOpen!();
      }

      context.go('/rooms/$roomId');
    }
  }

  void _goToDraftChat({
    required BuildContext context,
    required String path,
    required ContactPresentationSearch contactPresentationSearch,
  }) {
    if (contactPresentationSearch.matrixId ==
        Matrix.of(context).client.userID) {
      return;
    }

    Router.neglect(
      context,
      () => context.go(
        '/$path/draftChat',
        extra: {
          PresentationContactConstant.receiverId:
              contactPresentationSearch.matrixId ?? '',
          PresentationContactConstant.displayName:
              contactPresentationSearch.displayName ?? '',
          PresentationContactConstant.status: '',
        },
      ),
    );
  }

  Future<void> removeFromGroupChat() async {
    if (user == null) return;

    WarningDialog.hideWarningDialog(context);
    final result = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () => user!.ban(),
    );
    if (result.error != null) {
      if (!mounted) return;
      return TwakeSnackBar.show(context, result.error!.message);
    }
    widget.onUpdatedMembers?.call();
  }

  List<ProfileInfoActions> profileInfoActions() {
    return [
      ProfileInfoActions.sendMessage,
      if (user?.canKick == true) ProfileInfoActions.removeFromGroup,
      if (user?.room.canTransferOwnership == true && user?.isBanned == false)
        ProfileInfoActions.transferOwnership,
    ];
  }

  void handleActions(ProfileInfoActions action) {
    switch (action) {
      case ProfileInfoActions.sendMessage:
        openNewChat();
        break;
      case ProfileInfoActions.removeFromGroup:
        removeFromGroupChat();
        break;
      case ProfileInfoActions.transferOwnership:
        transferOwnership();
        break;
      default:
        break;
    }
  }

  Widget buildProfileInfoActions(BuildContext context) {
    return Column(
      children: [
        Divider(
          thickness: ProfileInfoBodyViewStyle.bigDividerThickness,
          color: LinagoraStateLayer(
            LinagoraSysColors.material().surfaceTint,
          ).opacityLayer3,
        ),
        Column(
          children: profileInfoActions().map((action) {
            return Column(
              children: [
                if (action.divider(context) != null) action.divider(context)!,
                InkWell(
                  key: Key('profile_action_${action.name}'),
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  onTap: () => handleActions(action),
                  child: Padding(
                    padding: action.padding(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 60,
                          ),
                          height: ProfileInfoBodyViewStyle.actionHeight,
                          decoration: action.decoration(context),
                          child: Row(
                            children: [
                              if (action.icon() != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: action.icon()!,
                                ),
                              Text(
                                action.label(context),
                                style: action.textStyle(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Transfer ownership of the room to the user
  ///
  /// Related to:
  ///   [SetPermissionLevelInteractor] to set the user's power level to owner and the current user's power level to admin
  ///   [DefaultPowerLevelMember] to get the power level of owner and admin
  ///
  Future<void> transferOwnership() async {
    if (user == null || user?.room == null) return;

    final L10n? translations = L10n.of(context);

    await showConfirmAlertDialog(
      context: context,
      title: translations?.confirmTransferOwnership(user?.displayName ?? ''),
      message: translations?.transferOwnershipDescription,
      okLabel: translations?.confirm,
      cancelLabel: translations?.cancel,
    ).then((result) {
      if (result == ConfirmResult.cancel) return;

      final Room room = user!.room;
      _setPermissionLevelSubscription = getIt
          .get<SetPermissionLevelInteractor>()
          .execute(
            room: room,
            userPermissionLevels: {
              user!: room.ownUser.powerLevel,
              room.ownUser: room.getUserDefaultLevel(),
            },
          )
          .listen(_handleSetPermissionState);
    });
  }

  /// Handles the result state of a permission level change operation.
  ///
  void _handleSetPermissionState(Either<Failure, Success> state) {
    state.fold(
      (Failure failure) {
        _setPermissionLevelSubscription?.cancel();
        if (!mounted) return;
        switch (failure) {
          case SetPermissionLevelFailure():
            TwakeDialog.hideLoadingDialog(context);
            TwakeSnackBar.show(context, failure.exception.toString());

          case NoPermissionFailure():
            TwakeDialog.hideLoadingDialog(context);
            TwakeSnackBar.show(
              context,
              L10n.of(context)!.permissionErrorChangeRole,
            );
          default:
            break;
        }
      },
      (Success success) {
        switch (success) {
          case SetPermissionLevelLoading():
            TwakeDialog.showLoadingDialog(context);

          case SetPermissionLevelSuccess():
            _setPermissionLevelSubscription?.cancel();
            if (!mounted) return;
            TwakeDialog.hideLoadingDialog(context);
            widget.onTransferOwnershipSuccess?.call();
          default:
            break;
        }
      },
    );
  }

  void onAvatarInfoTap() {
    if (!responsive.isMobile(context)) {
      return;
    }
    // Prevent rapid tapping during animation
    if (animationController.isAnimating ||
        (_avatarToggleTimer?.isActive ?? false)) {
      return;
    }
    if (animationController.isCompleted) {
      animationController.reverse();
      _avatarToggleTimer = Timer(
        const Duration(milliseconds: _animationDuration),
        () {
          if (mounted) {
            isExpandedAvatar.value = false;
          }
        },
      );
    } else {
      if (mounted) {
        isExpandedAvatar.value = true;
      }
      _avatarToggleTimer = Timer(
        const Duration(milliseconds: _animationDuration),
        () {
          if (mounted) {
            animationController.forward();
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) => ProfileInfoBodyView(controller: this);
}
