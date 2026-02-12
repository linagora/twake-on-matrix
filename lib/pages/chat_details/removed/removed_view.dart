import 'package:fluffychat/pages/chat_details/removed/removed.dart';
import 'package:fluffychat/pages/chat_details/removed/removed_search_state.dart';
import 'package:fluffychat/pages/chat_list/chat_list_header_style.dart';
import 'package:fluffychat/utils/user_extension.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/context_menu_builder_ios_paste_without_permission.dart';
import 'package:fluffychat/widgets/search/empty_search_widget.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:matrix/matrix.dart';

class RemovedView extends StatelessWidget {
  final RemovedController controller;

  const RemovedView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      resizeToAvoidBottomInset: false,
      appBar: TwakeAppBar(
        title: L10n.of(context)!.removedUsers,
        enableLeftTitle: true,
        leading: TwakeIconButton(
          paddingAll: 8,
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: controller.onBack,
          icon: Icons.arrow_back_ios,
        ),
        centerTitle: true,
        withDivider: true,
        context: context,
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
                decoration:
                    ChatListHeaderStyle.searchInputDecoration(
                      context,
                      prefixIconColor: LinagoraSysColors.material().tertiary,
                    ).copyWith(
                      hintStyle: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(
                            color: LinagoraSysColors.material().tertiary,
                          ),
                      hintText: L10n.of(context)!.enterAnEmailAddress,
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
                valueListenable: controller.searchUserResults,
                builder: (context, _, __) {
                  return Text(
                    L10n.of(
                      context,
                    )!.bannedUsersCount(controller.removedMember.length),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: LinagoraRefColors.material().neutral[40],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8.0),
            buildExceptionsListMobile(context),
            buildExceptionsListWeb(context),
          ],
        ),
      ),
    );
  }

  Widget buildExceptionsListMobile(BuildContext context) {
    if (!controller.responsive.isMobile(context)) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder(
      valueListenable: controller.searchUserResults,
      builder: (context, searchResults, child) {
        return searchResults.fold(
          (failure) {
            if (failure is RemovedSearchEmptyState) {
              return const Center(child: EmptySearchWidget());
            }
            return const SizedBox.shrink();
          },
          (success) {
            if (success is RemovedSearchSuccessState) {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: success.removedMember.length,
                itemBuilder: (context, index) {
                  final member = success.removedMember[index];
                  return TwakeInkWell(
                    onTap: () {
                      member.openProfileView(
                        context: context,
                        onTransferOwnershipSuccess: () {
                          controller.onBack();
                        },
                      );
                    },
                    child: _itemMemberBuilder(context: context, member: member),
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

  Widget buildExceptionsListWeb(BuildContext context) {
    if (controller.responsive.isMobile(context)) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder(
      valueListenable: controller.searchUserResults,
      builder: (context, searchResults, child) {
        return searchResults.fold(
          (failure) {
            if (failure is RemovedSearchEmptyState) {
              return const Center(child: EmptySearchWidget());
            }
            return const SizedBox.shrink();
          },
          (success) {
            if (success is RemovedSearchSuccessState) {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: success.removedMember.length,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemBuilder: (context, index) {
                  final member = success.removedMember[index];
                  return TwakeInkWell(
                    onTap: () {},
                    child: _itemMemberBuilder(context: context, member: member),
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

  Widget _itemMemberBuilder({
    required BuildContext context,
    required User member,
  }) {
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
                      InkWell(
                        splashColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        onTap: () => controller.handleOnTapUnbanUser(member),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: Row(
                            children: [
                              Icon(
                                Icons.block,
                                color: LinagoraSysColors.material().primary,
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                L10n.of(context)!.unban,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color:
                                          LinagoraSysColors.material().primary,
                                    ),
                              ),
                            ],
                          ),
                        ),
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
      ),
    );
  }
}
