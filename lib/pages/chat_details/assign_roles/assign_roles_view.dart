import 'package:fluffychat/pages/chat_details/assign_roles/assign_roles.dart';
import 'package:fluffychat/pages/chat_details/assign_roles/assign_roles_search_state.dart';
import 'package:fluffychat/pages/chat_list/chat_list_header_style.dart';
import 'package:fluffychat/utils/user_extension.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/context_menu_builder_ios_paste_without_permission.dart';
import 'package:fluffychat/widgets/search/empty_search_widget.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

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
        onBack: controller.onBack,
      ),

      /// Implement later
      floatingActionButton: InkWell(
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
                  hintText: L10n.of(context)!.searchContacts,
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
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                L10n.of(context)!.adminsOfTheGroup(
                  controller.assignRolesMember.length,
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
              return const Center(
                child: EmptySearchWidget(),
              );
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
                  final role =
                      member.getDefaultPowerLevelMember.displayName(context);
                  return TwakeInkWell(
                    onTap: () {},
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
                                    Row(
                                      children: [
                                        Text(
                                          role,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color:
                                                    LinagoraRefColors.material()
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
            if (failure is AssignRolesSearchEmptyState) {
              return const Center(
                child: EmptySearchWidget(),
              );
            }
            return const SizedBox.shrink();
          },
          (success) {
            if (success is AssignRolesSearchSuccessState) {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: success.assignRolesMember.length,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                ),
                itemBuilder: (context, index) {
                  final member = success.assignRolesMember[index];
                  final role =
                      member.getDefaultPowerLevelMember.displayName(context);
                  return TwakeInkWell(
                    onTap: () {},
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
                                    Row(
                                      children: [
                                        Text(
                                          role,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color:
                                                    LinagoraRefColors.material()
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
