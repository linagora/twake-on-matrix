import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_header_style.dart';
import 'package:fluffychat/pages/search/search.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/context_menu_builder_ios_paste_without_permission.dart';
import 'package:fluffychat/widgets/swipe_to_dismiss_wrap.dart';
import 'package:fluffychat/widgets/twake_components/twake_header.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_state_layer.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

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
          color: ChatListHeaderStyle.responsive.isMobile(context)
              ? LinagoraSysColors.material().background
              : Colors.transparent,
          height: ChatListHeaderStyle.searchBarContainerHeight,
          padding: ChatListHeaderStyle.searchInputPadding,
          child: PlatformInfos.isWeb
              ? _normalModeWidgetWeb(context)
              : _normalModeWidgetsMobile(context),
        ),
        if (ChatListHeaderStyle.responsive.isMobile(context))
          Divider(
            height: ChatListHeaderStyle.dividerHeight,
            thickness: ChatListHeaderStyle.dividerThickness,
            color: LinagoraStateLayer(LinagoraSysColors.material().surfaceTint)
                .opacityLayer3,
          ),
      ],
    );
  }

  Widget _normalModeWidgetsMobile(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _navigateWithSlideAnimation(context),
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

  void _navigateWithSlideAnimation(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return const SwipeToDismissWrap(
            child: Search(),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          final tween = Tween(begin: begin, end: end).chain(
            CurveTween(
              curve: curve,
            ),
          );
          final offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
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
            child: ValueListenableBuilder(
              valueListenable: controller.matrixState.showToMBootstrap,
              builder: (context, value, _) {
                return TextField(
                  textInputAction: TextInputAction.search,
                  contextMenuBuilder: mobileTwakeContextMenuBuilder,
                  enabled: false,
                  decoration:
                      ChatListHeaderStyle.searchInputDecoration(context),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
