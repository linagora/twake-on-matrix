import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/pages/chat_list/chat_list.dart';
import 'package:twake_chat/pages/chat_list/chat_list_body_view.dart';
import 'package:twake_chat/pages/chat_list/chat_list_bottom_navigator.dart';
import 'package:twake_chat/pages/chat_list/chat_list_bottom_navigator_style.dart';
import 'package:twake_chat/pages/chat_list/chat_list_header.dart';
import 'package:twake_chat/pages/chat_list/chat_list_view_style.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

class ChatListView extends StatefulWidget {
  final ChatListController controller;
  final Widget? bottomNavigationBar;
  final VoidCallback? onOpenSearchPageInMultipleColumns;
  final ChatListBottomNavigatorBarIcon onTapBottomNavigation;

  const ChatListView({
    super.key,
    required this.controller,
    this.bottomNavigationBar,
    this.onOpenSearchPageInMultipleColumns,
    required this.onTapBottomNavigation,
  });

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  final responsiveUtils = getIt.get<ResponsiveUtils>();
  // Keeps the header State when select mode swaps the sliver that wraps it.
  final _headerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.controller.matrixState.voiceMessageEvent,
      builder: (context, hasEvent, child) {
        final headerSize = ChatListViewStyle.preferredSizeAppBar(
          hasAudioEvent: hasEvent != null && PlatformInfos.isMobile,
        );
        final header = ChatListHeader(
          key: _headerKey,
          onOpenSearchPageInMultipleColumns:
              widget.onOpenSearchPageInMultipleColumns,
          controller: widget.controller,
        );
        // One column: the header scrolls away inside the list (ChatListBodyView),
        // so the viewport never resizes. Wide layouts keep it in the app bar.
        final collapsing = responsiveUtils.isMobile(context);
        return Scaffold(
          backgroundColor: LinagoraSysColors.material().onPrimary,
          appBar: collapsing
              ? null
              : PreferredSize(preferredSize: headerSize, child: header),
          bottomNavigationBar: ValueListenableBuilder(
            valueListenable: widget.controller.conversationSelectionNotifier,
            builder: (context, conversationSelection, __) {
              if (conversationSelection.isNotEmpty) {
                return ChatListBottomNavigator(
                  bottomNavigationActionsWidget: widget.controller
                      .bottomNavigationActionsWidget(
                        paddingIcon: ChatListBottomNavigatorStyle.paddingIcon,
                        iconSize: ChatListBottomNavigatorStyle.iconSize,
                        width: ChatListBottomNavigatorStyle.width,
                      ),
                );
              } else {
                return widget.bottomNavigationBar ?? const SizedBox();
              }
            },
          ),
          body: Stack(
            children: [
              StreamBuilder<Client>(
                stream: widget.controller.clientStream,
                builder: (context, snapshot) {
                  return ChatListBodyView(
                    widget.controller,
                    header: collapsing ? header : null,
                    // Same as Scaffold for a primary appBar: preferred height + status bar.
                    headerHeight:
                        headerSize.height + MediaQuery.paddingOf(context).top,
                  );
                },
              ),
              // Once the header has scrolled away, rows must not show behind
              // the status bar. Same colour as the header paints there.
              if (collapsing)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.paddingOf(context).top,
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: LinagoraSysColors.material().background,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
