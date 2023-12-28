import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_header_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_header.dart';
import 'package:flutter/material.dart';

class ChatListHeader extends StatelessWidget {
  final VoidCallback? onOpenSearchPage;
  final ChatListController controller;

  const ChatListHeader({
    Key? key,
    required this.controller,
    this.onOpenSearchPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TwakeHeader(
          controller: controller,
        ),
        Container(
          height: ChatListHeaderStyle.searchBarContainerHeight,
          padding: ChatListHeaderStyle.searchInputPadding,
          child: _normalModeWidgets(context),
        ),
      ],
    );
  }

  Widget _normalModeWidgets(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius:
                BorderRadius.circular(ChatListHeaderStyle.searchRadiusBorder),
            onTap: onOpenSearchPage,
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
