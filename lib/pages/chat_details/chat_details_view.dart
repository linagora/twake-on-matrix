import 'package:fluffychat/pages/chat_details/chat_details_app_bar.dart';
import 'package:fluffychat/pages/chat_details/chat_details_view_style.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:fluffychat/pages/chat_details/chat_details.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';

class ChatDetailsView extends StatelessWidget {
  final ChatDetailsController controller;

  const ChatDetailsView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (controller.room == null) {
      return Scaffold(
        backgroundColor: LinagoraSysColors.material().onPrimary,
        appBar: AppBar(
          backgroundColor: LinagoraSysColors.material().onPrimary,
          title: Text(L10n.of(context)!.oopsSomethingWentWrong),
        ),
        body: Center(
          child: Text(L10n.of(context)!.youAreNoLongerParticipatingInThisChat),
        ),
      );
    }
    return StreamBuilder(
      stream: controller.room?.onUpdate.stream,
      builder: (context, _) {
        return Scaffold(
          floatingActionButton: ListenableBuilder(
            listenable: controller.removeUsersChangeNotifier,
            builder: (context, _) {
              if (!controller
                  .removeUsersChangeNotifier.haveSelectedUsersNotifier.value) {
                return const SizedBox();
              }
              return _RemoveMembersButton(controller: controller);
            },
          ),
          backgroundColor: LinagoraSysColors.material().onPrimary,
          appBar: TwakeAppBar(
            title: L10n.of(context)!.groupInfo,
            leading: TwakeIconButton(
              paddingAll: 8,
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: controller.widget.closeRightColumn,
              icon: controller.widget.isInStack
                  ? Icons.arrow_back_ios
                  : Icons.close,
            ),
            enableLeftTitle: true,
            centerTitle: true,
            withDivider: true,
            actions: [
              if (controller.room?.canEditChatDetails == true)
                TextButton(
                  onPressed: controller.onTapEditButton,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    L10n.of(context)!.edit,
                    style: textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              else
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTapDown: (details) => controller.onTapMoreButton(
                    context,
                    details,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.more_vert, size: 24),
                  ),
                ),
            ],
            context: context,
          ),
          body: NestedScrollView(
            physics: const ClampingScrollPhysics(),
            key: controller.nestedScrollViewState,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              final room = controller.room;
              if (room == null) return [];
              return [
                ChatDetailsAppBar(
                  room: room,
                  tabList: controller.tabList,
                  tabController: controller.tabController,
                  muteNotifier: controller.muteNotifier,
                  onToggleNotification: controller.onToggleNotification,
                  innerBoxIsScrolled: innerBoxIsScrolled,
                  onSearch: controller.onTapSearch,
                  onMessage: controller.onTapMessage,
                ),
              ];
            },
            body: ClipRRect(
              borderRadius: BorderRadius.all(
                Radius.circular(
                  ChatDetailViewStyle.chatDetailsPageViewWebBorderRadius,
                ),
              ),
              child: Container(
                width: ChatDetailViewStyle.chatDetailsPageViewWebWidth,
                padding: ChatDetailViewStyle.paddingTabBarView,
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: controller.tabController,
                  children: controller.sharedPages().map((pages) {
                    return pages.child;
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RemoveMembersButton extends StatelessWidget {
  const _RemoveMembersButton({
    required this.controller,
  });

  final ChatDetailsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () async {
        final result = await TwakeDialog.showFutureLoadingDialogFullScreen(
          future: () => Future.wait(
            controller.removeUsersChangeNotifier.usersList.map(
              (user) => user.ban(),
            ),
          ),
        );
        if (result.error != null) {
          TwakeSnackBar.show(context, result.error!.message);
        }

        await controller.onUpdateMembers();
        controller.removeUsersChangeNotifier.unselectAllUsers();
      },
      borderRadius: ChatDetailViewStyle.borderRadiusButton,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xffffd2d7),
          borderRadius: ChatDetailViewStyle.borderRadiusButton,
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 24, 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_remove_outlined,
              size: 18.0,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                L10n.of(context)!.removeMember,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
