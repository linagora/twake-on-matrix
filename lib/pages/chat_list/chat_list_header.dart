import 'package:fluffychat/pages/chat_list/chat_list_header_style.dart';
import 'package:fluffychat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:fluffychat/presentation/model/chat_list/chat_selection_actions.dart';
import 'package:fluffychat/widgets/twake_components/twake_header.dart';
import 'package:flutter/material.dart';

class ChatListHeader extends StatelessWidget {
  final ValueNotifier<SelectMode> selectModeNotifier;
  final ValueNotifier<List<ConversationSelectionPresentation>>
      conversationSelectionNotifier;
  final VoidCallback openSelectMode;
  final VoidCallback? onOpenSearchPage;
  final VoidCallback onClearSelection;

  const ChatListHeader({
    Key? key,
    this.onOpenSearchPage,
    required this.selectModeNotifier,
    required this.openSelectMode,
    required this.conversationSelectionNotifier,
    required this.onClearSelection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TwakeHeader(
          conversationSelectionNotifier: conversationSelectionNotifier,
          selectModeNotifier: selectModeNotifier,
          openSelectMode: openSelectMode,
          onClearSelection: onClearSelection,
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
