import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_header_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class ChatListHeader extends StatelessWidget {
  final ChatListController controller;
  final VoidCallback? onOpenSearchPage;

  const ChatListHeader({
    Key? key,
    required this.controller,
    this.onOpenSearchPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectMode = controller.selectMode;

    Widget child;

    switch (selectMode) {
      case SelectMode.select:
        child = _selectModeWidgets(context);
      case SelectMode.normal:
        child = _normalModeWidgets(context);
      default:
        child = _normalModeWidgets(context);
    }

    return Column(
      children: [
        TwakeHeader(controller: controller),
        Container(
          height: ChatListHeaderStyle.searchBarContainerHeight,
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 16.0),
          child: child,
        )
      ],
    );
  }

  Widget _selectModeWidgets(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: L10n.of(context)!.cancel,
          icon: const Icon(Icons.close_outlined),
          onPressed: controller.cancelAction,
          color: Theme.of(context).colorScheme.primary,
        ),
        Expanded(
          child: Text(
            controller.selectedRoomIds.length.toString(),
            key: const ValueKey(SelectMode.select),
          ),
        ),
        IconButton(
          tooltip: L10n.of(context)!.toggleUnread,
          icon: Icon(
            controller.anySelectedRoomNotMarkedUnread
                ? Icons.mark_chat_read_outlined
                : Icons.mark_chat_unread_outlined,
          ),
          onPressed: controller.toggleUnread,
        ),
        IconButton(
          tooltip: L10n.of(context)!.toggleFavorite,
          icon: Icon(
            controller.anySelectedRoomNotFavorite
                ? Icons.push_pin_outlined
                : Icons.push_pin,
          ),
          onPressed: controller.toggleFavouriteRoom,
        ),
        IconButton(
          icon: Icon(
            controller.anySelectedRoomNotMuted
                ? Icons.notifications_off_outlined
                : Icons.notifications_outlined,
          ),
          tooltip: L10n.of(context)!.toggleMuted,
          onPressed: controller.toggleMuted,
        ),
        IconButton(
          icon: const Icon(Icons.archive_outlined),
          tooltip: L10n.of(context)!.archive,
          onPressed: controller.archiveAction,
        ),
      ],
    );
  }

  Widget _normalModeWidgets(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(24.0),
            onTap: onOpenSearchPage,
            child: TextField(
              controller: controller.searchChatController,
              textInputAction: TextInputAction.search,
              onChanged: controller.onSearchEnter,
              enabled: false,
              decoration: InputDecoration(
                filled: true,
                contentPadding: const EdgeInsets.all(0),
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(
                    ChatListHeaderStyle.searchRadiusBorder,
                  ),
                ),
                hintText: L10n.of(context)!.search,
                hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: LinagoraRefColors.material().neutral[60],
                    ),
                floatingLabelBehavior: FloatingLabelBehavior.never,
                prefixIcon: Icon(
                  Icons.search_outlined,
                  size: 24,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                suffixIcon: const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
