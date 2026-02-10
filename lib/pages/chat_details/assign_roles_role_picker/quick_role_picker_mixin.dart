import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/set_permission_level_state.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/domain/usecase/room/set_permission_level_interactor.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action.dart';
import 'package:fluffychat/widgets/mixins/twake_context_menu_mixin.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

mixin QuickRolePickerMixin on TwakeContextMenuMixin {
  final List<DefaultPowerLevelMember> quickRolePicker = [
    DefaultPowerLevelMember.admin,
    DefaultPowerLevelMember.moderator,
    DefaultPowerLevelMember.member,
    DefaultPowerLevelMember.guest,
  ];
  final setPermissionLevelInteractor = getIt
      .get<SetPermissionLevelInteractor>();
  StreamSubscription<Either<Failure, Success>>? _setPermissionLevelSubscription;

  List<ContextMenuAction> _mapPopupRolesToContextMenuActions(
    BuildContext context, {
    required User user,
  }) {
    return quickRolePicker.map((action) {
      return ContextMenuAction(
        name: action.displayName(context),
        icon: action.powerLevel == user.powerLevel ? Icons.check : null,
        colorIcon: LinagoraRefColors.material().neutral[30],
      );
    }).toList();
  }

  void handleClickOnContextMenuItem(
    BuildContext context, {
    required Room room,
    required Map<User, int> userPermissionLevels,
    VoidCallback? onHandledResult,
  }) {
    _setPermissionLevelSubscription = setPermissionLevelInteractor
        .execute(room: room, userPermissionLevels: userPermissionLevels)
        .listen(
          (result) {
            _handleAssignRolesResult(context, result);
          },
          onDone: () {
            _setPermissionLevelSubscription?.cancel();
            onHandledResult?.call();
          },
        );
  }

  void _handleAssignRolesResult(
    BuildContext context,
    Either<Failure, Success> result,
  ) {
    result.fold(
      (failure) {
        if (failure is SetPermissionLevelFailure) {
          TwakeDialog.hideLoadingDialog(context);
          TwakeSnackBar.show(context, failure.exception.toString());
          return;
        }

        if (failure is NoPermissionFailure) {
          TwakeDialog.hideLoadingDialog(context);
          TwakeSnackBar.show(
            context,
            L10n.of(context)!.permissionErrorChangeRole,
          );
          return;
        }
      },
      (success) {
        if (success is SetPermissionLevelLoading) {
          TwakeDialog.showLoadingDialog(context);
          return;
        }

        if (success is SetPermissionLevelSuccess) {
          TwakeDialog.hideLoadingDialog(context);

          return;
        }
      },
    );
  }

  Widget _quickRolePickerItem({
    required BuildContext dialogContext,
    required BuildContext loadingContext,
    required DefaultPowerLevelMember role,
    required Room room,
    required User user,
    VoidCallback? onHandledResult,
  }) {
    return InkWell(
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
      splashColor: Colors.transparent,
      onTap: () {
        Navigator.of(dialogContext).pop();
        handleClickOnContextMenuItem(
          userPermissionLevels: {user: role.powerLevel},
          loadingContext,
          room: room,
          onHandledResult: onHandledResult,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        margin: const EdgeInsets.only(bottom: 8),
        height: 36,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                role.displayName(dialogContext),
                style: dialogContext.textTheme.bodyLarge?.copyWith(
                  color: LinagoraSysColors.material().onSurface,
                ),
              ),
            ),
            if (role.powerLevel == user.powerLevel)
              SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  Icons.check,
                  color: LinagoraSysColors.material().onSurface,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> handleOnTapQuickRolePickerWeb({
    required BuildContext context,
    required TapDownDetails tapDownDetails,
    required Room room,
    required User user,
    VoidCallback? onHandledResult,
  }) async {
    if (!room.canUpdateRoleInRoom(user)) {
      return;
    }
    final offset = tapDownDetails.globalPosition;

    final selectedActionIndex = await showTwakeContextMenu(
      offset: offset,
      context: context,
      listActions: _mapPopupRolesToContextMenuActions(context, user: user),
    );

    if (selectedActionIndex != null && selectedActionIndex is int) {
      handleClickOnContextMenuItem(
        context,
        room: room,
        userPermissionLevels: {
          user: quickRolePicker[selectedActionIndex].powerLevel,
        },
        onHandledResult: onHandledResult,
      );
    }
  }

  Future<void> handleOnTapQuickRolePickerMobile({
    required BuildContext rootContext,
    required Room room,
    required User user,
    VoidCallback? onHandledResult,
  }) async {
    if (!room.canUpdateRoleInRoom(user)) {
      return;
    }
    await showModalBottomSheet(
      context: rootContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      isScrollControlled: true,
      builder: (dialogContext) => Container(
        width: double.infinity,
        padding: MediaQuery.viewInsetsOf(dialogContext),
        child: DraggableScrollableSheet(
          initialChildSize: 0.3,
          minChildSize: 0.3,
          maxChildSize: 0.5,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 12),
              child: Column(
                children: [
                  Container(
                    height: 4,
                    width: 32,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: LinagoraSysColors.material().outline,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: quickRolePicker
                          .map(
                            (role) => _quickRolePickerItem(
                              dialogContext: dialogContext,
                              loadingContext: rootContext,
                              role: role,
                              room: room,
                              user: user,
                              onHandledResult: onHandledResult,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
