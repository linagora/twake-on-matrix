import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/update_pinned_events_state.dart';
import 'package:fluffychat/domain/enums/pinned_messages_action_enum.dart';
import 'package:fluffychat/domain/usecase/room/update_pinned_messages_interactor.dart';
import 'package:fluffychat/pages/chat/chat_context_menu_actions.dart';
import 'package:fluffychat/pages/chat/chat_horizontal_action_menu.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_messages_screen.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_messages_style.dart';
import 'package:fluffychat/pages/chat/chat_view_style.dart';
import 'package:fluffychat/pages/chat/context_item_chat_action.dart';
import 'package:fluffychat/presentation/model/forward/forward_argument.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/mixins/popup_context_menu_action_mixin.dart';
import 'package:fluffychat/widgets/mixins/popup_menu_widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
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

  ValueNotifier<List<Event>> selectedEvents = ValueNotifier([]);

  List<String> get selectedPinnedEventsIds =>
      selectedEvents.value.map((event) => event.eventId).toList();

  final ValueNotifier<bool> openingPopupMenu = ValueNotifier(false);

  List<Widget> pinnedMessagesActionsList(
    BuildContext context,
    Event event,
  ) {
    final listAction = [
      ChatContextMenuActions.select,
      ChatContextMenuActions.copyMessage,
      ChatContextMenuActions.pinChat,
      ChatContextMenuActions.forward,
      if (PlatformInfos.isWeb && event.hasAttachment)
        ChatContextMenuActions.downloadFile,
    ];
    return listAction.map((action) {
      return InkWell(
        onTap: () async {
          await _handleClickOnContextMenuItem(action, event);
          Navigator.of(context).pop();
        },
        child: Container(
          height: PinnedMessagesStyle.heightContextMenuItem,
          padding: const EdgeInsets.all(
            PinnedMessagesStyle.paddingAllContextMenuItem,
          ),
          child: Row(
            children: [
              Icon(
                action.getIcon(
                  unpin: event.isPinned,
                  isSelected: isSelected(event),
                ),
                color: Theme.of(context).colorScheme.onSurface,
              ),
              PinnedMessagesStyle.paddingIconAndUnpin,
              Flexible(
                child: Text(
                  action.getTitle(
                    context,
                    unpin: event.isPinned,
                    isSelected: isSelected(event),
                  ),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void unpin(String eventId) {
    updatePinnedMessagesInteractor
        .execute(room: room!, eventIds: [eventId]).listen((event) {
      event.fold((failure) {
        _showErrorSnackbar(failure);
      }, (success) {
        if (success is UpdatePinnedEventsSuccess) {
          eventsNotifier.value = eventsNotifier.value
              .where((event) => event?.eventId != eventId)
              .toList();
          if (eventsNotifier.value.isEmpty) {
            Navigator.of(context).pop(eventsNotifier.value);
          }
        }
      });
    });
  }

  void unpinAll() {
    updatePinnedMessagesInteractor
        .execute(
      room: room!,
      eventIds: [],
      action: PinnedMessagesActionEnum.unpinAll,
    )
        .listen((event) {
      event.fold(
        (failure) {
          _showErrorSnackbar(failure);
        },
        (success) {
          if (success is UpdatePinnedEventsSuccess) {
            eventsNotifier.value = [];
            Navigator.of(context).pop();
          }
        },
      );
    });
  }

  void unpinSelectedEvents() {
    updatePinnedMessagesInteractor
        .execute(
      room: room!,
      eventIds: selectedPinnedEventsIds,
    )
        .listen(
      (event) {
        event.fold(
          (failure) {
            _showErrorSnackbar(failure);
          },
          (success) {
            if (success is UpdatePinnedEventsSuccess) {
              eventsNotifier.value = eventsNotifier.value
                  .where(
                    (event) =>
                        !selectedPinnedEventsIds.contains(event?.eventId),
                  )
                  .toList();
              selectedEvents.value = [];
              if (eventsNotifier.value.isEmpty) {
                Navigator.of(context).pop();
              }
            }
          },
        );
      },
    );
  }

  void _showErrorSnackbar(Failure failure) {
    if (failure is UnpinEventsFailure) {
      TwakeSnackBar.show(context, L10n.of(context)!.failedToUnpin);
    } else if (failure is UpdatePinnedEventsFailure) {
      TwakeSnackBar.show(
        context,
        failure.exception.toLocalizedString(context),
      );
    }
  }

  bool isSelected(Event event) => selectedEvents.value.any(
        (e) => e.eventId == event.eventId,
      );

  void closeSelectionMode() {
    selectedEvents.value = [];
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

  void onSelectMessage(Event event) {
    if (!event.redacted) {
      if (selectedEvents.value.contains(event)) {
        selectedEvents.value =
            selectedEvents.value.where((element) => element != event).toList();
      } else {
        selectedEvents.value = [...selectedEvents.value, event];
      }
    }
  }

  void _initPinnedEvents() {
    if (widget.pinnedEvents.isNotEmpty) {
      eventsNotifier.value = widget.pinnedEvents;
    } else {
      final currentRoomId = GoRouterState.of(context).pathParameters['roomid'];
      if (currentRoomId != null) {
        context.go('/rooms/$currentRoomId');
      }
    }
  }

  void onClickBackButton() {
    Navigator.of(context).pop(
      eventsNotifier.value != widget.pinnedEvents ? eventsNotifier.value : null,
    );
  }

  List<ContextMenuItemChatAction> listHorizontalActionMenuBuilder() {
    final listAction = [
      ChatHorizontalActionMenu.more,
    ];
    return listAction
        .map(
          (action) => ContextMenuItemChatAction(
            action,
            action.getContextMenuItemState(),
          ),
        )
        .toList();
  }

  void onHover(bool isHovered, int index, Event event) {
    if (widget.pinnedEvents.asMap().containsKey(index) &&
        PinnedMessagesStyle.responsiveUtils.isWebDesktop(context) &&
        !openingPopupMenu.value) {
      isHoverNotifier.value = isHovered ? event.eventId : null;
    }
  }

  void handleHorizontalActionMenu(
    BuildContext context,
    ChatHorizontalActionMenu actions,
    Event event,
    TapDownDetails tapDownDetails,
  ) {
    switch (actions) {
      case ChatHorizontalActionMenu.more:
        handleContextMenuAction(
          context,
          event,
          tapDownDetails,
        );
        break;
      default:
        break;
    }
  }

  void _handleStateContextMenu() {
    openingPopupMenu.toggle();
  }

  List<PopupMenuItem> _popupMenuActionTile(
    BuildContext context,
    Event event,
  ) {
    final listAction = [
      ChatContextMenuActions.select,
      ChatContextMenuActions.copyMessage,
      ChatContextMenuActions.pinChat,
      ChatContextMenuActions.forward,
      if (PlatformInfos.isWeb && event.hasAttachment)
        ChatContextMenuActions.downloadFile,
    ];
    return listAction.map((action) {
      return PopupMenuItem(
        padding: EdgeInsets.zero,
        child: popupItemByTwakeAppRouter(
          context,
          action.getTitle(
            context,
            unpin: event.isPinned,
            isSelected: isSelected(event),
          ),
          iconAction: action.getIcon(unpin: event.isPinned),
          onCallbackAction: () => _handleClickOnContextMenuItem(
            action,
            event,
          ),
        ),
      );
    }).toList();
  }

  Future<void> _handleClickOnContextMenuItem(
    ChatContextMenuActions action,
    Event event,
  ) async {
    switch (action) {
      case ChatContextMenuActions.select:
        onSelectMessage(event);
        break;
      case ChatContextMenuActions.copyMessage:
        await event.copy(context, widget.timeline!);
        break;
      case ChatContextMenuActions.pinChat:
        unpin(event.eventId);
        break;
      case ChatContextMenuActions.forward:
        forwardEventAction(event);
        break;
      case ChatContextMenuActions.downloadFile:
        await event.saveFile(context);
        break;
      default:
        break;
    }
  }

  void forwardEventAction(Event event) async {
    Matrix.of(context).shareContent =
        event.getDisplayEvent(widget.timeline!).content;
    Logs().d(
      "forwardEventsAction():: shareContent: ${Matrix.of(context).shareContent}",
    );
    context.go(
      '/rooms/forward',
      extra: ForwardArgument(
        fromRoomId: event.roomId ?? '',
      ),
    );
  }

  void handleContextMenuAction(
    BuildContext context,
    Event event,
    TapDownDetails tapDownDetails,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final offset = tapDownDetails.globalPosition;
    final position = RelativeRect.fromLTRB(
      offset.dx,
      offset.dy + ChatViewStyle.paddingBottomContextMenu,
      screenSize.width - offset.dx,
      screenSize.height - offset.dy,
    );
    _handleStateContextMenu();
    openPopupMenuAction(
      context,
      position,
      _popupMenuActionTile(context, event),
      onClose: () {
        _handleStateContextMenu();
      },
    );
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _initPinnedEvents();
    });
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
