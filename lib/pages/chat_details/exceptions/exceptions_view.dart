import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/pages/chat_details/exceptions/exceptions.dart';
import 'package:fluffychat/pages/chat_details/exceptions/exceptions_search_state.dart';
import 'package:fluffychat/pages/chat_list/chat_list_header_style.dart';
import 'package:fluffychat/utils/user_extension.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/context_menu_builder_ios_paste_without_permission.dart';
import 'package:fluffychat/widgets/search/empty_search_widget.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class ExceptionsView extends StatelessWidget {
  final ExceptionsController controller;

  const ExceptionsView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      resizeToAvoidBottomInset: false,
      appBar: TwakeAppBar(
        title: L10n.of(context)!.exceptions,
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
              child: Text(
                L10n.of(
                  context,
                )!.readOnlyCount(controller.exceptionsMember.length),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: LinagoraRefColors.material().neutral[40],
                ),
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
            if (failure is ExceptionsSearchEmptyState) {
              return const Center(child: EmptySearchWidget());
            }
            return const SizedBox.shrink();
          },
          (success) {
            if (success is ExceptionsSearchSuccessState) {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: success.exceptionsMember.length,
                itemBuilder: (context, index) {
                  final member = success.exceptionsMember[index];
                  final role = member.getDefaultPowerLevelMember.displayName(
                    context,
                  );

                  return _itemMemberBuilder(
                    context: context,
                    member: member,
                    role: role,
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
            if (failure is ExceptionsSearchEmptyState) {
              return const Center(child: EmptySearchWidget());
            }
            return const SizedBox.shrink();
          },
          (success) {
            if (success is ExceptionsSearchSuccessState) {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: success.exceptionsMember.length,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemBuilder: (context, index) {
                  final member = success.exceptionsMember[index];
                  final role = member.getDefaultPowerLevelMember.displayName(
                    context,
                  );
                  return _itemMemberBuilder(
                    context: context,
                    member: member,
                    role: role,
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
    required String role,
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
                      const SizedBox(width: 8.0),
                      _rolePicker(context, member: member, role: role),
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

  Widget _rolePicker(
    BuildContext context, {
    required User member,
    required String role,
  }) => InkWell(
    hoverColor: Colors.transparent,
    highlightColor: Colors.transparent,
    focusColor: Colors.transparent,
    splashColor: Colors.transparent,
    onTapDown: !controller.widget.room.canUpdateRoleInRoom(member)
        ? null
        : (details) => handleOnTapQuickRolePicker(
            context,
            room: controller.widget.room,
            member: member,
            tapDownDetails: details,
            onHandledResult: controller.refreshView,
          ),
    child: Row(
      children: [
        Text(
          role,
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
    ),
  );

  void handleOnTapQuickRolePicker(
    BuildContext context, {
    required User member,
    required Room room,
    required TapDownDetails tapDownDetails,
    VoidCallback? onHandledResult,
  }) {
    if (controller.responsive.isMobile(context)) {
      controller.handleOnTapQuickRolePickerMobile(
        rootContext: context,
        room: room,
        user: member,
        onHandledResult: onHandledResult,
      );
    } else {
      controller.handleOnTapQuickRolePickerWeb(
        context: context,
        room: room,
        user: member,
        tapDownDetails: tapDownDetails,
        onHandledResult: onHandledResult,
      );
    }
  }
}
