import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_member_picker/assign_roles_member_picker.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_member_picker/assign_roles_member_picker_search_state.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_member_picker/assign_roles_member_picker_style.dart';
import 'package:fluffychat/pages/chat_list/chat_list_header_style.dart';
import 'package:fluffychat/utils/user_extension.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/context_menu_builder_ios_paste_without_permission.dart';
import 'package:fluffychat/widgets/search/empty_search_widget.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:fluffychat/widgets/twake_components/twake_text_button.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:matrix/matrix.dart';

class AssignRolesMemberPickerView extends StatelessWidget {
  final AssignRolesPickerController controller;
  final bool isDialog;

  const AssignRolesMemberPickerView({
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
                  onTap: () => Navigator.of(context).pop(),
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
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: controller.textEditingController,
                        contextMenuBuilder: mobileTwakeContextMenuBuilder,
                        focusNode: controller.inputFocus,
                        textInputAction: TextInputAction.search,
                        autofocus: false,
                        onTapOutside: (_) {
                          controller.inputFocus.unfocus();
                        },
                        decoration:
                            ChatListHeaderStyle.searchInputDecoration(
                              context,
                              prefixIconColor:
                                  LinagoraSysColors.material().tertiary,
                            ).copyWith(
                              hintStyle: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color:
                                        LinagoraSysColors.material().tertiary,
                                  ),
                              hintText: L10n.of(context)!.searchGroupMembers,
                              suffixIcon: ValueListenableBuilder(
                                valueListenable:
                                    controller.textEditingController,
                                builder: (context, value, child) =>
                                    value.text.isNotEmpty
                                    ? IconButton(
                                        onPressed: () {
                                          controller.textEditingController
                                              .clear();
                                        },
                                        icon: const Icon(Icons.close),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: LinagoraStateLayer(
                        LinagoraSysColors.material().surfaceTint,
                      ).opacityLayer3,
                    ),
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
                      margin: EdgeInsets.symmetric(
                        horizontal: isDialog ? 16.0 : 0,
                      ),
                      child: Text(
                        L10n.of(
                          context,
                        )!.memberOfTheGroup(controller.members.length),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: LinagoraRefColors.material().neutral[40],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    buildAssignRolesListMobile(context),
                    buildAssignRolesListWeb(context),
                  ],
                ),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: controller
                  .selectedUsersMapChangeNotifier
                  .haveSelectedUsersNotifier,
              builder: (context, haveSelectedContacts, child) {
                if (!haveSelectedContacts) {
                  return const SizedBox.shrink();
                }
                return child!;
              },
              child: Container(
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
                      message: L10n.of(context)!.next,
                      onTap: () {
                        controller.navigateToAssignRolesEditor(context);
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget selectedUsersList(BuildContext context) {
    final usersNotifier = controller.selectedUsersMapChangeNotifier;

    return AnimatedSize(
      curve: Curves.easeIn,
      alignment: Alignment.bottomCenter,
      duration: const Duration(milliseconds: 250),
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width,
        child: ListenableBuilder(
          listenable: usersNotifier,
          builder: (context, Widget? child) {
            if (usersNotifier.usersList.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                bottom: isDialog ? 8 : 16,
                right: 24,
              ),
              child: Wrap(
                spacing: 8.0,
                children: usersNotifier.usersList.map((member) {
                  return Container(
                    decoration: BoxDecoration(
                      color: LinagoraStateLayer(
                        LinagoraSysColors.material().surfaceTint,
                      ).opacityLayer3,
                      borderRadius: BorderRadius.circular(
                        AssignRolesMemberPickerStyle.avatarChipSize,
                      ),
                    ),
                    margin: AssignRolesMemberPickerStyle.chipMargin,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Avatar(
                          mxContent: member.avatarUrl,
                          name: member.calcDisplayname(),
                          size: AssignRolesMemberPickerStyle.avatarChipSize,
                        ),
                        const SizedBox(width: 4.0),
                        Flexible(
                          child: Padding(
                            padding:
                                AssignRolesMemberPickerStyle.textChipPadding,
                            child: Text(
                              member.calcDisplayname(),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color:
                                        LinagoraSysColors.material().onSurface,
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
            );
          },
        ),
      ),
    );
  }

  Widget buildAssignRolesListMobile(BuildContext context) {
    if (!controller.responsive.isMobile(context)) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder(
      valueListenable: controller.searchUserResults,
      builder: (context, searchResults, child) {
        return searchResults.fold(
          (failure) {
            if (failure is AssignRolesMemberPickerSearchEmptyState) {
              return const Center(child: EmptySearchWidget());
            }
            return const SizedBox.shrink();
          },
          (success) {
            if (success is AssignRolesMemberPickerSearchSuccessState) {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: success.members.length,
                itemBuilder: (context, index) {
                  final member = success.members[index];
                  final role = member.getDefaultPowerLevelMember.displayName(
                    context,
                  );
                  final canUpdateRole = controller.widget.room
                      .canUpdateRoleInRoom(member);
                  return TwakeInkWell(
                    onTap: !canUpdateRole
                        ? null
                        : () {
                            controller.selectedUsersMapChangeNotifier
                                .onUserTileTap(context, member);
                          },
                    child: TwakeListItem(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          ValueListenableBuilder<bool>(
                            valueListenable: controller
                                .selectedUsersMapChangeNotifier
                                .getNotifierAtUser(member),
                            builder: (context, isCurrentSelected, child) {
                              return Checkbox(
                                value: !canUpdateRole || isCurrentSelected,
                                side: BorderSide(
                                  color: isCurrentSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : LinagoraRefColors.material()
                                            .tertiary[30]!,
                                  width: 2,
                                ),
                                onChanged: !canUpdateRole
                                    ? null
                                    : (newValue) {
                                        controller
                                            .selectedUsersMapChangeNotifier
                                            .onUserTileTap(context, member);
                                      },
                              );
                            },
                          ),
                          const SizedBox(width: 8.0),
                          _informationItemBuilder(
                            context: context,
                            member: member,
                            role: role,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget buildAssignRolesListWeb(BuildContext context) {
    if (controller.responsive.isMobile(context)) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder(
      valueListenable: controller.searchUserResults,
      builder: (context, searchResults, child) {
        return searchResults.fold(
          (failure) {
            if (failure is AssignRolesMemberPickerSearchEmptyState) {
              return const Center(child: EmptySearchWidget());
            }
            return const SizedBox.shrink();
          },
          (success) {
            if (success is AssignRolesMemberPickerSearchSuccessState) {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: success.members.length,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemBuilder: (context, index) {
                  final member = success.members[index];
                  final role = member.getDefaultPowerLevelMember.displayName(
                    context,
                  );
                  final canUpdateRole = controller.widget.room
                      .canUpdateRoleInRoom(member);
                  return TwakeInkWell(
                    onTap: !canUpdateRole
                        ? null
                        : () {
                            controller.selectedUsersMapChangeNotifier
                                .onUserTileTap(context, member);
                          },
                    child: TwakeListItem(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          ValueListenableBuilder<bool>(
                            valueListenable: controller
                                .selectedUsersMapChangeNotifier
                                .getNotifierAtUser(member),
                            builder: (context, isCurrentSelected, child) {
                              return Checkbox(
                                value: !canUpdateRole || isCurrentSelected,
                                side: BorderSide(
                                  color: isCurrentSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : LinagoraRefColors.material()
                                            .tertiary[30]!,
                                  width: 2,
                                ),
                                onChanged: !canUpdateRole
                                    ? null
                                    : (newValue) {
                                        controller
                                            .selectedUsersMapChangeNotifier
                                            .onUserTileTap(context, member);
                                      },
                              );
                            },
                          ),
                          const SizedBox(width: 8.0),
                          _informationItemBuilder(
                            context: context,
                            member: member,
                            role: role,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _informationItemBuilder({
    required BuildContext context,
    required User member,
    required String role,
  }) {
    return Expanded(
      child: Row(
        children: [
          Avatar(mxContent: member.avatarUrl, name: member.calcDisplayname()),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.calcDisplayname(),
                        style: LinagoraTextStyle.material().bodyMedium2
                            .copyWith(
                              color: LinagoraSysColors.material().onSurface,
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    if (member.isOwnerRole)
                      Row(
                        children: [
                          Text(
                            role,
                            style:
                                AssignRolesMemberPickerStyle.roleNameTextStyle(
                                  context,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                  ],
                ),
                Text(
                  member.id,
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
}
