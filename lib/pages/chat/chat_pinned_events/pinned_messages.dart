import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_messages_screen.dart';
import 'package:fluffychat/presentation/model/chat/pop_up_menu_item_model.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/mixins/popup_context_menu_action_mixin.dart';
import 'package:fluffychat/widgets/mixins/popup_menu_widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class PinnedMessages extends StatefulWidget {
  final List<Event?> pinnedEvents;

  final Timeline? timeline;

  const PinnedMessages({super.key, required this.pinnedEvents, this.timeline});

  @override
  State<StatefulWidget> createState() => PinnedMessagesController();
}

class PinnedMessagesController extends State<PinnedMessages>
    with PopupContextMenuActionMixin, PopupMenuWidgetMixin {
  ValueNotifier<List<Event?>> eventsNotifier = ValueNotifier([]);

  final ValueNotifier<String?> isHoverNotifier = ValueNotifier(null);

  final ScrollController scrollController = ScrollController();

  List<ContextMenuItemModel> get pinnedMessagesActionsList => [
        ContextMenuItemModel(
          text: L10n.of(context)!.unpin,
          imagePath: ImagePaths.icUnpin,
          color: Theme.of(context).colorScheme.onSurface,
          onTap: ({extra}) async {
            if (extra is Event) {
              final result = await extra.unpin();
              if (result) {
                eventsNotifier.value.remove(extra);
                eventsNotifier.value = List.from(eventsNotifier.value);
                if (eventsNotifier.value.isEmpty) {
                  Navigator.of(context).pop(eventsNotifier.value);
                }
              } else {
                TwakeSnackBar.show(context, L10n.of(context)!.failedToUnpin);
              }
            }
          },
        ),
        ContextMenuItemModel(
          text: L10n.of(context)!.jumpToMessage,
          imagePath: ImagePaths.icJumpTo,
          color: Theme.of(context).colorScheme.onSurface,
          onTap: ({extra}) async {
            if (extra is Event) {
              Navigator.pop(context, extra);
            }
          },
        ),
        ContextMenuItemModel(
          text: L10n.of(context)!.copy,
          iconData: Icons.content_copy,
          color: Theme.of(context).colorScheme.onSurface,
          onTap: ({extra}) async {
            if (extra is Event && widget.timeline != null) {
              await extra.copy(context, widget.timeline!);
            }
          },
        ),
      ];

  void unpinAll() {
    widget.pinnedEvents.first?.room.setPinnedEvents([]);
    Navigator.of(context).pop();
  }

  void handleContextMenuActionInMore(
    BuildContext context,
  ) {
    openPopupMenuAction(
      context,
      context.getCurrentRelativeRectOfWidget(),
      [
        PopupMenuItem(
          padding: EdgeInsets.zero,
          child: popupItemByTwakeAppRouter(
            context,
            L10n.of(context)!.unpinAllMessages,
            imagePath: ImagePaths.icUnpin,
            colorIcon: Theme.of(context).colorScheme.onSurface,
            onCallbackAction: () => unpinAll(),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    eventsNotifier.value = widget.pinnedEvents;
  }

  @override
  void dispose() {
    scrollController.dispose();
    eventsNotifier.dispose();
    isHoverNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PinnedMessagesScreen(this);
  }
}
