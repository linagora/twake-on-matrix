import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_role_picker/assign_roles_role_picker.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_role_picker/assign_roles_role_picker_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/expandable_widget.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:fluffychat/widgets/twake_components/twake_text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

class AssignRolesRolePickerView extends StatelessWidget {
  final AssignRolesEditorController controller;
  final bool isDialog;

  const AssignRolesRolePickerView({
    super.key,
    required this.controller,
    this.isDialog = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDialog
          ? Colors.transparent
          : LinagoraSysColors.material().onPrimary,
      resizeToAvoidBottomInset: false,
      appBar: TwakeAppBar(
        title: L10n.of(context)!.assignRoles,
        centerTitle: true,
        withDivider: true,
        context: context,
        enableLeftTitle: true,
        isDialog: isDialog,
        backgroundColor: isDialog ? Colors.transparent : null,
        leading: TwakeIconButton(
          paddingAll: 8,
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () => Navigator.of(context).pop(),
          icon: Icons.arrow_back_ios,
        ),
        actions: isDialog
            ? [
                TwakeIconButton(
                  paddingAll: 8,
                  splashColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  icon: Icons.close,
                ),
              ]
            : null,
      ),
      body: SizedBox(
        height: double.infinity,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 56),
                child: Column(
                  children: [
                    selectedUsersList(context),
                    Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      margin: isDialog
                          ? const EdgeInsets.symmetric(horizontal: 16)
                          : null,
                      child: Text(
                        L10n.of(context)!.selectRole,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: LinagoraRefColors.material().neutral[40],
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        return ValueListenableBuilder(
                          valueListenable: controller.roleSelectedNotifier,
                          builder: (context, isSelected, child) {
                            return _expandableItemWidget(
                              context: context,
                              index: index,
                              isSelected: isSelected,
                            );
                          },
                        );
                      },
                      itemCount:
                          controller.widget.rolePickerType.assignRoles.length,
                    ),
                  ],
                ),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: controller.roleSelectedNotifier,
              builder: (context, roleSelected, child) {
                if (roleSelected == null) {
                  return const SizedBox.shrink();
                }
                return Container(
                  padding: EdgeInsets.only(
                    bottom: 24,
                    left: 16,
                    right: isDialog ? 36 : 16,
                    top: isDialog ? 36 : 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 32),
                        child: TwakeTextButton(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          message: L10n.of(context)!.cancel,
                          borderHover: 100,
                          buttonDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          styleMessage: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                      TwakeTextButton(
                        message: L10n.of(context)!.done,
                        onTap: () {
                          controller.onTapToDoneButton();
                        },
                        styleMessage: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                        borderHover: 100,
                        buttonDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _expandableItemWidget({
    required BuildContext context,
    required int index,
    DefaultPowerLevelMember? isSelected,
  }) {
    return ExpandableWidget(
      dividerPadding: isDialog
          ? const EdgeInsets.symmetric(horizontal: 16)
          : null,
      isExpanded:
          isSelected == controller.widget.rolePickerType.assignRoles[index],
      parentWidget: Row(
        children: [
          Container(
            width: AssignRolesRolePickerStyle.assignRoleIconSize,
            height: AssignRolesRolePickerStyle.assignRoleIconSize,
            decoration: BoxDecoration(
              color: controller.colorBackgroundForRoles(
                controller.widget.rolePickerType.assignRoles[index],
              ),
              borderRadius: BorderRadius.circular(
                AssignRolesRolePickerStyle.assignRoleIconSize / 2,
              ),
            ),
            child: Center(
              child: controller.iconForRoles(
                controller.widget.rolePickerType.assignRoles[index],
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.widget.rolePickerType.assignRoles[index]
                      .displayName(context),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: LinagoraSysColors.material().onSurface,
                  ),
                ),
                Text(
                  controller.subtitleForRoles(
                    controller.widget.rolePickerType.assignRoles[index],
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LinagoraRefColors.material().tertiary[20],
                  ),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: SizedBox(
              width: 24,
              height: 24,
              child: SvgPicture.asset(
                isSelected ==
                        controller.widget.rolePickerType.assignRoles[index]
                    ? ImagePaths.icRadioChecked
                    : ImagePaths.icRadioUnchecked,
              ),
            ),
          ),
        ],
      ),
      childWidget: controller.permissionsWidgetForRoles(
        controller.widget.rolePickerType.assignRoles[index],
      ),
      onTap: () {
        controller.onSelectedRole(
          controller.widget.rolePickerType.assignRoles[index],
        );
      },
    );
  }

  Widget selectedUsersList(BuildContext context) {
    final users = controller.widget.assignedUsers;

    if (users.isEmpty) {
      return const SizedBox.shrink();
    }
    if (users.length == 1) {
      return TwakeListItem(
        padding: const EdgeInsets.all(8),
        margin: EdgeInsets.symmetric(horizontal: isDialog ? 16 : 0),
        child: Row(
          children: [
            Avatar(
              mxContent: users.first.avatarUrl,
              name: users.first.calcDisplayname(),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          users.first.calcDisplayname(),
                          style: LinagoraTextStyle.material().bodyMedium2
                              .copyWith(
                                color: LinagoraSysColors.material().onSurface,
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    users.first.id,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: LinagoraRefColors.material().tertiary[30],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return AnimatedSize(
      curve: Curves.easeIn,
      alignment: Alignment.bottomCenter,
      duration: const Duration(milliseconds: 250),
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width,
        child: Padding(
          padding: EdgeInsets.only(
            left: isDialog ? 16 : 8,
            bottom: 8,
            right: isDialog ? 16 : 8,
          ),
          child: Wrap(
            spacing: 8.0,
            children: users.map((member) {
              return Container(
                decoration: BoxDecoration(
                  color: LinagoraStateLayer(
                    LinagoraSysColors.material().surfaceTint,
                  ).opacityLayer3,
                  borderRadius: BorderRadius.circular(
                    AssignRolesRolePickerStyle.avatarChipSize,
                  ),
                ),
                margin: AssignRolesRolePickerStyle.chipMargin,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Avatar(
                      mxContent: member.avatarUrl,
                      name: member.calcDisplayname(),
                      size: AssignRolesRolePickerStyle.avatarChipSize,
                    ),
                    const SizedBox(width: 4.0),
                    Flexible(
                      child: Padding(
                        padding: AssignRolesRolePickerStyle.textChipPadding,
                        child: Text(
                          member.calcDisplayname(),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: LinagoraSysColors.material().onSurface,
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
