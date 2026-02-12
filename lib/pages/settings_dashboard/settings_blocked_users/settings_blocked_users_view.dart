import 'package:fluffychat/pages/chat_list/chat_list_header_style.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_blocked_users/settings_blocked_users_search_state.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact_constant.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/context_menu_builder_ios_paste_without_permission.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/search/empty_search_widget.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'settings_blocked_user.dart';

class SettingsBlockedUsersView extends StatelessWidget {
  final SettingsIgnoreListController controller;

  const SettingsBlockedUsersView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      resizeToAvoidBottomInset: false,
      appBar: TwakeAppBar(
        title: L10n.of(context)!.blockedUsers,
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
      body: MaxWidthBody(
        withScrolling: true,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
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
              ValueListenableBuilder(
                valueListenable: controller.searchUserResults,
                builder: (context, searchResults, child) {
                  return searchResults.fold(
                    (failure) {
                      if (failure is BlockedUsersSearchEmptyState) {
                        return const Center(child: EmptySearchWidget());
                      }
                      return const SizedBox.shrink();
                    },
                    (success) {
                      if (success is BlockedUsersSearchSuccessState) {
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: success.blockedUsers.length,
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          itemBuilder: (context, index) {
                            final profile = success.blockedUsers[index];

                            return TwakeInkWell(
                              onTap: () {},
                              child: _itemMemberBuilder(
                                context: context,
                                profile: profile,
                                responsiveUtils: controller.responsiveUtils,
                              ),
                            );
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemMemberBuilder({
    required BuildContext context,
    required Profile profile,
    required ResponsiveUtils responsiveUtils,
  }) {
    return TwakeInkWell(
      onTap: () {
        final roomId = Matrix.of(
          context,
        ).client.getDirectChatFromUserId(profile.userId);
        if (roomId == null) {
          if (profile.userId != Matrix.of(context).client.userID) {
            Router.neglect(
              context,
              () => context.go(
                '/rooms/draftChat',
                extra: {
                  PresentationContactConstant.receiverId: profile.userId,
                  PresentationContactConstant.displayName:
                      profile.displayName ?? '',
                  PresentationContactConstant.status: '',
                },
              ),
            );
          }
        } else {
          if (responsiveUtils.isMobile(context)) {
            context.push('/rooms/$roomId');
          } else {
            context.go('/rooms/$roomId');
          }
        }
      },
      child: TwakeListItem(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Avatar(
              mxContent: profile.avatarUrl,
              name: profile.displayName ?? '',
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
                          profile.displayName ?? '',
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
                    profile.userId,
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
