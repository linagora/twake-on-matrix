import 'package:animations/animations.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_header_style.dart';
import 'package:fluffychat/pages/search/search.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/swipe_to_dismiss_wrap.dart';
import 'package:fluffychat/widgets/twake_components/twake_header.dart';
import 'package:flutter/material.dart';

class ChatListHeader extends StatelessWidget {
  final ChatListController controller;
  final VoidCallback? onOpenSearchPageInMultipleColumns;

  const ChatListHeader({
    super.key,
    required this.controller,
    this.onOpenSearchPageInMultipleColumns,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TwakeHeader(
          onClearSelection: controller.onClickClearSelection,
          client: controller.activeClient,
          selectModeNotifier: controller.selectModeNotifier,
          conversationSelectionNotifier:
              controller.conversationSelectionNotifier,
          onClickAvatar: controller.onClickAvatar,
        ),
        Container(
          height: ChatListHeaderStyle.searchBarContainerHeight,
          padding: ChatListHeaderStyle.searchInputPadding,
          child: PlatformInfos.isWeb
              ? _normalModeWidgetWeb(context)
              : _normalModeWidgetsMobile(context),
        ),
      ],
    );
  }

  Widget _normalModeWidgetsMobile(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OpenContainer(
            openBuilder: (context, _) {
              return const SwipeToDismissWrap(
                child: Search(),
              );
            },
            closedBuilder: (context, action) => TextField(
              textInputAction: TextInputAction.search,
              enabled: false,
              decoration: ChatListHeaderStyle.searchInputDecoration(context),
            ),
            closedElevation: 0,
            transitionDuration: const Duration(milliseconds: 500),
            transitionType: ContainerTransitionType.fade,
            closedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                ChatListHeaderStyle.searchRadiusBorder,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _normalModeWidgetWeb(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius:
                BorderRadius.circular(ChatListHeaderStyle.searchRadiusBorder),
            onTap: onOpenSearchPageInMultipleColumns,
            child: TextField(
              textInputAction: TextInputAction.search,
              enabled: false,
              decoration: ChatListHeaderStyle.searchInputDecoration(context),
            ),
          ),
        ),
      ],
    );
  }
}
