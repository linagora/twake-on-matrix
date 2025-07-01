import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_editor/assign_roles_editor_style.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_editor/assign_roles_editor_view.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class AssignRolesEditor extends StatefulWidget {
  final Room room;
  final List<User> assignedUsers;
  final bool isDialog;

  const AssignRolesEditor({
    super.key,
    required this.room,
    required this.assignedUsers,
    this.isDialog = false,
  });

  @override
  AssignRolesEditorController createState() => AssignRolesEditorController();
}

class AssignRolesEditorController extends State<AssignRolesEditor> {
  final responsive = getIt.get<ResponsiveUtils>();

  final ValueNotifier<DefaultPowerLevelMember?> roleSelectedNotifier =
      ValueNotifier<DefaultPowerLevelMember?>(null);

  final List<DefaultPowerLevelMember> assignRoles = [
    DefaultPowerLevelMember.guest,
    DefaultPowerLevelMember.member,
    DefaultPowerLevelMember.moderator,
    DefaultPowerLevelMember.admin,
  ];

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
          width: AssignRolesEditorStyle.roleIconSize,
          height: AssignRolesEditorStyle.roleIconSize,
          colorFilter: ColorFilter.mode(
            LinagoraSysColors.material().onPrimary,
            BlendMode.srcIn,
          ),
        );
      case DefaultPowerLevelMember.member:
        return Icon(
          Icons.person_outline,
          size: AssignRolesEditorStyle.roleIconSize,
          color: LinagoraSysColors.material().onPrimary,
        );
      case DefaultPowerLevelMember.moderator:
        return SvgPicture.asset(
          ImagePaths.icShieldLockFill,
          width: AssignRolesEditorStyle.roleIconSize,
          height: AssignRolesEditorStyle.roleIconSize,
          colorFilter: ColorFilter.mode(
            LinagoraSysColors.material().onPrimary,
            BlendMode.srcIn,
          ),
        );
      case DefaultPowerLevelMember.admin:
        return Icon(
          Icons.star_outline,
          size: AssignRolesEditorStyle.roleIconSize,
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
        borderRadius: BorderRadius.all(
          Radius.circular(16.0),
        ),
      ),
      child: AssignRolesEditorView(
        controller: this,
        isDialog: widget.isDialog,
      ),
    );
  }
}
