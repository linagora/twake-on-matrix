import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/pages/chat_details/assign_roles/assign_roles.dart';
import 'package:fluffychat/pages/chat_details/assign_roles/assign_roles_search_state.dart';
import 'package:fluffychat/pages/chat_details/assign_roles/assign_roles_style.dart';
import 'package:fluffychat/pages/chat_list/chat_list_header_style.dart';
import 'package:fluffychat/utils/user_extension.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/context_menu_builder_ios_paste_without_permission.dart';
import 'package:fluffychat/widgets/search/empty_search_widget.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class AssignRolesView extends StatelessWidget {
  final AssignRolesController controller;

  const AssignRolesView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      resizeToAvoidBottomInset: false,
      appBar: TwakeAppBar(
        title: L10n.of(context)!.permissions,
        centerTitle: true,
        withDivider: true,
        context: context,
        enableLeftTitle: true,
        leading: TwakeIconButton(
          paddingAll: 8,
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: controller.onBack,
          icon: Icons.arrow_back_ios,
        ),
      ),

      /// Implement later
      floatingActionButton: ValueListenableBuilder(
        valueListenable: controller.enableSelectMembersMobileNotifier,
        builder: (context, enableSelectMembers, child) {
          if (enableSelectMembers) {
            return ValueListenableBuilder<bool>(
              valueListenable: controller
                  .selectedUsersMapChangeNotifier
                  .haveSelectedUsersNotifier,
              builder: (context, hasSelectedUsers, _) {
                if (!hasSelectedUsers) {
                  return child!;
                }
                return InkWell(
                  borderRadius: BorderRadius.circular(100),
                  splashColor: LinagoraHoverStyle.material().hoverColor,
                  onTap: controller.handleDemoteMultiAdminsAndModeratorsMobile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: LinagoraSysColors.material().errorContainer,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_remove_outlined,
                          size: 18.0,
                          color:
                              LinagoraSysColors.material().onSecondaryContainer,
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          L10n.of(context)!.demoteAdminsModerators,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: LinagoraSysColors.material()
                                    .onSecondaryContainer,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return child!;
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          splashColor: LinagoraHoverStyle.material().hoverColor,
          onTap: () {
            controller.goToAssignRolesPicker();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: LinagoraSysColors.material().secondaryContainer,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_add_outlined,
                  size: 18.0,
                  color: LinagoraSysColors.material().onSecondaryContainer,
                ),
                const SizedBox(width: 8.0),
                Text(
                  L10n.of(context)!.addAdminsOrModerators,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: LinagoraSysColors.material().onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: FocusManager.instance.primaryFocus?.unfocus,
        excludeFromSemantics: true,
        behavior: HitTestBehavior.translucent,
        child: SlidableAutoCloseBehavior(
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
                                color: LinagoraSysColors.material().tertiary,
                              ),
                          hintText: L10n.of(context)!.searchContacts,
                          suffixIcon: ValueListenableBuilder(
                            valueListenable: controller.textEditingController,
                            builder: (context, value, child) =>
                                value.text.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      controller.textEditingController.clear();
                                    },
                                    icon: const Icon(Icons.close),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                  ),
                ),
                Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: ValueListenableBuilder(
                    valueListenable: controller.membersNotifier,
                    builder: (context, members, child) {
                      return Text(
                        L10n.of(context)!.adminsOfTheGroup(members.length),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: LinagoraRefColors.material().neutral[40],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8.0),
                buildAssignRolesListMobile(context),
                buildAssignRolesListWeb(context),
              ],
            ),
          ),
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
            if (failure is AssignRolesSearchEmptyState) {
              return const Center(child: EmptySearchWidget());
            }
            return const SizedBox.shrink();
          },
          (success) {
            if (success is AssignRolesSearchSuccessState) {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: success.assignRolesMember.length,
                itemBuilder: (context, index) {
                  final member = success.assignRolesMember[index];
                  final canUpdateRole = controller.widget.room
                      .canUpdateRoleInRoom(member);
                  final slidables = controller.getSlidables(
                    context: context,
                    user: member,
                  );
                  return ValueListenableBuilder(
                    valueListenable:
                        controller.enableSelectMembersMobileNotifier,
                    builder: (context, enableSelectMembers, child) {
                      return Slidable(
                        groupTag: 'slidable_list',
                        enabled: slidables.isNotEmpty,
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          extentRatio: AssignRolesStyle.slidableExtentRatio(
                            slidables.length,
                          ),
                          children: slidables,
                        ),
                        child: TwakeInkWell(
                          onLongPress: () => controller.handleOnLongPressMobile(
                            member: member,
                          ),
                          onTap: () {
                            if (enableSelectMembers && canUpdateRole) {
                              controller.selectedUsersMapChangeNotifier
                                  .onUserTileTap(context, member);
                            } else {
                              member.openProfileView(
                                context: context,
                                onTransferOwnershipSuccess: () {
                                  controller.onBack();
                                },
                              );
                            }
                          },
                          child: TwakeListItem(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                if (enableSelectMembers)
                                  ValueListenableBuilder<bool>(
                                    valueListenable: controller
                                        .selectedUsersMapChangeNotifier
                                        .getNotifierAtUser(member),
                                    builder: (context, isCurrentSelected, child) {
                                      if (!canUpdateRole) {
                                        return const SizedBox.shrink();
                                      }
                                      return Checkbox(
                                        value:
                                            !canUpdateRole || isCurrentSelected,
                                        side: BorderSide(
                                          color: isCurrentSelected
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : LinagoraRefColors.material()
                                                    .tertiary[30]!,
                                          width: 2,
                                        ),
                                        onChanged: !canUpdateRole
                                            ? null
                                            : (newValue) {
                                                controller
                                                    .selectedUsersMapChangeNotifier
                                                    .onUserTileTap(
                                                      context,
                                                      member,
                                                    );
                                              },
                                      );
                                    },
                                  ),
                                const SizedBox(width: 8.0),
                                Avatar(
                                  mxContent: member.avatarUrl,
                                  name: member.calcDisplayname(),
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              member.calcDisplayname(),
                                              style: LinagoraTextStyle.material()
                                                  .bodyMedium2
                                                  .copyWith(
                                                    color:
                                                        LinagoraSysColors.material()
                                                            .onSurface,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          const SizedBox(width: 8.0),
                                          InkWell(
                                            hoverColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            focusColor: Colors.transparent,
                                            splashColor: Colors.transparent,
                                            onTap: () => controller
                                                .handleOnTapQuickRolePickerMobile(
                                                  rootContext: context,
                                                  user: member,
                                                  room: controller.widget.room,
                                                  onHandledResult: controller
                                                      .selectedUsersMapChangeNotifier
                                                      .unselectAllUsers,
                                                ),
                                            child: _assignRoleItemStreamBuilder(
                                              context: context,
                                              member: member,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        member.id,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color:
                                                  LinagoraRefColors.material()
                                                      .tertiary[30],
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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
            if (failure is AssignRolesSearchEmptyState) {
              return const Center(child: EmptySearchWidget());
            }
            return const SizedBox.shrink();
          },
          (success) {
            if (success is AssignRolesSearchSuccessState) {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: success.assignRolesMember.length,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemBuilder: (context, index) {
                  final member = success.assignRolesMember[index];
                  return TwakeInkWell(
                    onTap: () {
                      member.openProfileView(
                        context: context,
                        onTransferOwnershipSuccess: () {
                          controller.onBack();
                        },
                      );
                    },
                    child: TwakeListItem(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Avatar(
                            mxContent: member.avatarUrl,
                            name: member.calcDisplayname(),
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
                                        member.calcDisplayname(),
                                        style: LinagoraTextStyle.material()
                                            .bodyMedium2
                                            .copyWith(
                                              color:
                                                  LinagoraSysColors.material()
                                                      .onSurface,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    InkWell(
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      splashColor: Colors.transparent,
                                      onTapDown: (details) => controller
                                          .handleOnTapQuickRolePickerWeb(
                                            context: context,
                                            tapDownDetails: details,
                                            user: member,
                                            room: controller.widget.room,
                                            onHandledResult: controller
                                                .selectedUsersMapChangeNotifier
                                                .unselectAllUsers,
                                          ),
                                      child: _assignRoleItemStreamBuilder(
                                        context: context,
                                        member: member,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  member.id,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: LinagoraRefColors.material()
                                            .tertiary[30],
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
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

  Widget _assignRoleItemStreamBuilder({
    required BuildContext context,
    required User member,
  }) {
    return StreamBuilder(
      stream: controller.widget.room.powerLevelsChanged,
      builder: (context, date) {
        return Row(
          children: [
            Text(
              member.getDefaultPowerLevelMember.displayName(context),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: LinagoraRefColors.material().tertiary[30],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(width: 4),
            if (controller.widget.room.canUpdateRoleInRoom(member))
              Icon(
                Icons.arrow_drop_down,
                color: LinagoraRefColors.material().tertiary[30],
              ),
          ],
        );
      },
    );
  }
}
