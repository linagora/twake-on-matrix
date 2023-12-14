import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/update_pinned_events_state.dart';
import 'package:fluffychat/domain/usecase/room/update_pinned_messages_interactor.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_messages_screen.dart';
import 'package:fluffychat/presentation/model/chat/pop_up_menu_item_model.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
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

  final updatePinnedMessagesInteractor =
      getIt.get<UpdatePinnedMessagesInteractor>();

  Room? get room => widget.pinnedEvents.first?.room;

  List<ContextMenuItemModel> get pinnedMessagesActionsList => [
        ContextMenuItemModel(
          text: L10n.of(context)!.unpin,
          imagePath: ImagePaths.icUnpin,
          color: Theme.of(context).colorScheme.onSurface,
          onTap: ({extra}) async {
            if (extra is Event) {
              unpin(extra.eventId);
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

  void unpin(String eventId) {
    updatePinnedMessagesInteractor
        .execute(room: room!, eventIds: [eventId]).listen((event) {
      event.fold((failure) {
        if (failure is UnpinEventsFailure) {
          TwakeSnackBar.show(context, L10n.of(context)!.failedToUnpin);
        } else if (failure is UpdatePinnedEventsFailure) {
          TwakeSnackBar.show(
            context,
            failure.exception.toLocalizedString(context),
          );
        }
      }, (success) {
        if (success is UpdatePinnedEventsSuccess) {
          eventsNotifier.value
              .removeWhere((element) => element?.eventId == eventId);
          eventsNotifier.value = List.from(eventsNotifier.value);
          if (eventsNotifier.value.isEmpty) {
            Navigator.of(context).pop(eventsNotifier.value);
          }
        }
      });
    });
  }

  void unpinAll() {
    updatePinnedMessagesInteractor
        .execute(room: room!, eventIds: []).listen((event) {
      if (event is UpdatePinnedEventsSuccess) {
        eventsNotifier.value = [];
        Navigator.of(context).pop();
      } else if (event is UnpinEventsFailure) {
        TwakeSnackBar.show(context, L10n.of(context)!.failedToUnpin);
      }
    });
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
