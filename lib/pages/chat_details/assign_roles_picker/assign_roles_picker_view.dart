import 'package:fluffychat/pages/chat_details/assign_roles_picker/assign_roles_picker.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_picker/assign_roles_picker_search_state.dart';
import 'package:fluffychat/pages/chat_details/assign_roles_picker/assign_roles_picker_style.dart';
import 'package:fluffychat/pages/chat_list/chat_list_header_style.dart';
import 'package:fluffychat/utils/user_extension.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/context_menu_builder_ios_paste_without_permission.dart';
import 'package:fluffychat/widgets/search/empty_search_widget.dart';
import 'package:fluffychat/widgets/twake_components/twake_fab.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class AssignRolesPickerView extends StatelessWidget {
  final AssignRolesPickerController controller;

  const AssignRolesPickerView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      resizeToAvoidBottomInset: false,
      appBar: TwakeAppBar(
        title: L10n.of(context)!.assignRoles,
        centerTitle: true,
        withDivider: true,
        context: context,
        enableLeftTitle: true,
        leading: TwakeIconButton(
          paddingAll: 8,
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () => Navigator.of(context).pop(),
          icon: Icons.arrow_back_ios,
        ),
      ),
      floatingActionButton: controller.responsive.isMobile(context)
          ? ValueListenableBuilder<bool>(
              valueListenable: controller
                  .selectedUsersMapChangeNotifier.haveSelectedUsersNotifier,
              builder: (context, haveSelectedContacts, child) {
                if (!haveSelectedContacts) {
                  return const SizedBox.shrink();
                }
                return child!;
              },
              child: TwakeFloatingActionButton(
                icon: Icons.arrow_forward,
                onTap: () {
                  controller.navigateToAssignRolesEditor(context);
                },
              ),
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: controller.textEditingController,
                contextMenuBuilder: mobileTwakeContextMenuBuilder,
                focusNode: controller.inputFocus,
                textInputAction: TextInputAction.search,
                autofocus: true,
                decoration: ChatListHeaderStyle.searchInputDecoration(
                  context,
                  prefixIconColor: LinagoraSysColors.material().tertiary,
                ).copyWith(
                  hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: LinagoraSysColors.material().tertiary,
                      ),
                  hintText: L10n.of(context)!.enterAnEmailAddress,
                  suffixIcon: ValueListenableBuilder(
                    valueListenable: controller.textEditingController,
                    builder: (context, value, child) => value.text.isNotEmpty
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
            selectedUsersListMobile(context),
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                L10n.of(context)!.memberOfTheGroup(
                  controller.members.length,
                ),
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
    );
  }

  Widget selectedUsersListMobile(BuildContext context) {
    if (!controller.responsive.isMobile(context)) {
      return const SizedBox.shrink();
    }
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
              padding: const EdgeInsets.only(
                left: 24,
                bottom: 16,
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
                        AssignRolesPickerStyle.avatarChipSize,
                      ),
                    ),
                    margin: AssignRolesPickerStyle.chipMargin,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Avatar(
                          mxContent: member.avatarUrl,
                          name: member.calcDisplayname(),
                          size: AssignRolesPickerStyle.avatarChipSize,
                        ),
                        const SizedBox(width: 4.0),
                        Padding(
                          padding: AssignRolesPickerStyle.textChipPadding,
                          child: Text(
                            member.calcDisplayname(),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: LinagoraSysColors.material().onSurface,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
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
            if (failure is AssignRolesPickerSearchEmptyState) {
              return const Center(
                child: EmptySearchWidget(),
              );
            }
            return const SizedBox.shrink();
          },
          (success) {
            if (success is AssignRolesPickerSearchSuccessState) {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: success.members.length,
                itemBuilder: (context, index) {
                  final member = success.members[index];
                  final role =
                      member.getDefaultPowerLevelMember.displayName(context);
                  return TwakeInkWell(
                    onTap: member.isOwnerRole
                        ? null
                        : () {
                            controller.selectedUsersMapChangeNotifier
                                .onUserTileTap(
                              context,
                              member,
                            );
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
                                value: member.isOwnerRole || isCurrentSelected,
                                onChanged: member.isOwnerRole
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      member.calcDisplayname(),
                                      style: LinagoraTextStyle.material()
                                          .bodyMedium2
                                          .copyWith(
                                            color: LinagoraSysColors.material()
                                                .onSurface,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const Spacer(),
                                    if (member.isOwnerRole)
                                      Row(
                                        children: [
                                          Text(
                                            role,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  color: LinagoraRefColors
                                                          .material()
                                                      .tertiary[30],
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          const SizedBox(
                                            width: 4,
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                Text(
                                  member.id,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
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

  Widget buildAssignRolesListWeb(BuildContext context) {
    if (controller.responsive.isMobile(context)) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder(
      valueListenable: controller.searchUserResults,
      builder: (context, searchResults, child) {
        return searchResults.fold(
          (failure) {
            if (failure is AssignRolesPickerSearchEmptyState) {
              return const Center(
                child: EmptySearchWidget(),
              );
            }
            return const SizedBox.shrink();
          },
          (success) {
            if (success is AssignRolesPickerSearchSuccessState) {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: success.members.length,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                ),
                itemBuilder: (context, index) {
                  final member = success.members[index];
                  final role =
                      member.getDefaultPowerLevelMember.displayName(context);
                  return TwakeInkWell(
                    onTap: member.isOwnerRole
                        ? null
                        : () {
                            controller.selectedUsersMapChangeNotifier
                                .onUserTileTap(
                              context,
                              member,
                            );
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
                                value: member.isOwnerRole || isCurrentSelected,
                                onChanged: member.isOwnerRole
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      member.calcDisplayname(),
                                      style: LinagoraTextStyle.material()
                                          .bodyMedium2
                                          .copyWith(
                                            color: LinagoraSysColors.material()
                                                .onSurface,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const Spacer(),
                                    if (member.isOwnerRole)
                                      Row(
                                        children: [
                                          Text(
                                            role,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  color: LinagoraRefColors
                                                          .material()
                                                      .tertiary[30],
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          const SizedBox(
                                            width: 4,
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                Text(
                                  member.id,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
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
}
