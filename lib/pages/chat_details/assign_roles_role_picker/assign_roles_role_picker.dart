import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/set_permission_level_state.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/domain/usecase/room/set_permission_level_interactor.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_role_picker/assign_roles_role_picker_style.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_role_picker/assign_roles_role_picker_view.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_role_picker/role_picker_type_enum.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

class AssignRolesRolePicker extends StatefulWidget {
  final Room room;
  final List<User> assignedUsers;
  final bool isDialog;
  final RolePickerTypeEnum rolePickerType;
  final VoidCallback? onSuccess;

  const AssignRolesRolePicker({
    super.key,
    required this.room,
    required this.assignedUsers,
    this.isDialog = false,
    this.rolePickerType = RolePickerTypeEnum.none,
    this.onSuccess,
  });

  @override
  AssignRolesEditorController createState() => AssignRolesEditorController();
}

class AssignRolesEditorController extends State<AssignRolesRolePicker> {
  final responsive = getIt.get<ResponsiveUtils>();

  final ValueNotifier<DefaultPowerLevelMember?> roleSelectedNotifier =
      ValueNotifier<DefaultPowerLevelMember?>(null);

  final setPermissionLevelInteractor = getIt
      .get<SetPermissionLevelInteractor>();

  Color colorBackgroundForRoles(DefaultPowerLevelMember role) {
    switch (role) {
      case DefaultPowerLevelMember.guest:
        return const Color(0xFFF8BBD0);
      case DefaultPowerLevelMember.member:
        return const Color(0xFFB39DDB);
      case DefaultPowerLevelMember.moderator:
        return const Color(0xFFFFCA28);
      case DefaultPowerLevelMember.admin:
        return const Color(0xFF00C853);
      default:
        return LinagoraSysColors.material().onPrimary;
    }
  }

  String subtitleForRoles(DefaultPowerLevelMember role) {
    switch (role) {
      case DefaultPowerLevelMember.guest:
        return L10n.of(context)!.canReadMessages;
      case DefaultPowerLevelMember.member:
        return L10n.of(context)!.canWriteMessagesSendReacts;
      case DefaultPowerLevelMember.moderator:
        return L10n.of(context)!.canRemoveUsersDeleteMessages;
      case DefaultPowerLevelMember.admin:
        return L10n.of(context)!.canAccessAllFeaturesAndSettings;
      default:
        return '';
    }
  }

  Widget iconForRoles(DefaultPowerLevelMember role) {
    switch (role) {
      case DefaultPowerLevelMember.guest:
        return SvgPicture.asset(
          ImagePaths.icGhost,
          width: AssignRolesRolePickerStyle.roleIconSize,
          height: AssignRolesRolePickerStyle.roleIconSize,
          colorFilter: ColorFilter.mode(
            LinagoraSysColors.material().onPrimary,
            BlendMode.srcIn,
          ),
        );
      case DefaultPowerLevelMember.member:
        return Icon(
          Icons.person_outline,
          size: AssignRolesRolePickerStyle.roleIconSize,
          color: LinagoraSysColors.material().onPrimary,
        );
      case DefaultPowerLevelMember.moderator:
        return SvgPicture.asset(
          ImagePaths.icShieldLockFill,
          width: AssignRolesRolePickerStyle.roleIconSize,
          height: AssignRolesRolePickerStyle.roleIconSize,
          colorFilter: ColorFilter.mode(
            LinagoraSysColors.material().onPrimary,
            BlendMode.srcIn,
          ),
        );
      case DefaultPowerLevelMember.admin:
        return Icon(
          Icons.star_outline,
          size: AssignRolesRolePickerStyle.roleIconSize,
          color: LinagoraSysColors.material().onPrimary,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget permissionsWidgetForRoles(DefaultPowerLevelMember role) {
    switch (role) {
      case DefaultPowerLevelMember.guest:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: role
              .permissionForGuest(context)
              .map((permission) => permission.permissionViewWidget(context))
              .toList(),
        );
      case DefaultPowerLevelMember.member:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: role
              .permissionForMember(context)
              .map((permission) => permission.permissionViewWidget(context))
              .toList(),
        );
      case DefaultPowerLevelMember.moderator:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: role
              .permissionForModerator(context)
              .map((permission) => permission.permissionViewWidget(context))
              .toList(),
        );
      case DefaultPowerLevelMember.admin:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: role
              .permissionForAdmin(context)
              .map((permission) => permission.permissionViewWidget(context))
              .toList(),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void onSelectedRole(DefaultPowerLevelMember role) {
    if (role == roleSelectedNotifier.value) {
      roleSelectedNotifier.value = null;
    } else {
      if (role != DefaultPowerLevelMember.none) {
        roleSelectedNotifier.value = role;
      } else {
        roleSelectedNotifier.value = null;
      }
    }
  }

  void onTapToDoneButton() {
    if (roleSelectedNotifier.value == null) {
      return;
    }

    final Map<User, int> userPermissionLevels = {};

    for (final user in widget.assignedUsers) {
      userPermissionLevels[user] = roleSelectedNotifier.value!.powerLevel;
    }

    setPermissionLevelInteractor
        .execute(room: widget.room, userPermissionLevels: userPermissionLevels)
        .listen((result) {
          _handleAssignRolesResult(result);
        });
  }

  void _handleAssignRolesResult(Either<Failure, Success> result) {
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
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else if (responsive.isMobile(context)) {
            Navigator.of(
              context,
            ).popUntil((route) => route.settings.name == '/assign_roles');
          } else {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }

          return;
        }
      },
    );
  }

  void _handleGetDefaultPowerLevelSelected() {
    if (widget.rolePickerType == RolePickerTypeEnum.addAdminOrModerator) {
      roleSelectedNotifier.value = DefaultPowerLevelMember.moderator;
    } else {
      roleSelectedNotifier.value =
          DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
            usersDefault: widget.room.getUserDefaultLevel(),
          );
    }
  }

  @override
  void initState() {
    _handleGetDefaultPowerLevelSelected();
    super.initState();
  }

  @override
  void dispose() {
    roleSelectedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LinagoraSysColors.material().onPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
      ),
      child: AssignRolesRolePickerView(
        controller: this,
        isDialog: widget.isDialog,
      ),
    );
  }
}
