import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/room/update_pinned_events_state.dart';
import 'package:fluffychat/domain/enums/pinned_messages_action_enum.dart';
import 'package:fluffychat/domain/usecase/room/update_pinned_messages_interactor.dart';
import 'package:fluffychat/pages/chat/chat_context_menu_actions.dart';
import 'package:fluffychat/pages/chat/chat_horizontal_action_menu.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_messages_screen.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_messages_style.dart';
import 'package:fluffychat/pages/chat/context_item_chat_action.dart';
import 'package:fluffychat/presentation/extensions/event_update_extension.dart';
import 'package:fluffychat/presentation/model/forward/forward_argument.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/adaptive_bottom_sheet.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/mixins/popup_context_menu_action_mixin.dart';
import 'package:fluffychat/widgets/mixins/popup_menu_widget_mixin.dart';
import 'package:fluffychat/widgets/mixins/twake_context_menu_mixin.dart';
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
    with
        PopupContextMenuActionMixin,
        PopupMenuWidgetMixin,
        TwakeContextMenuMixin {
  ValueNotifier<List<Event?>> eventsNotifier = ValueNotifier([]);

  final ValueNotifier<String?> isHoverNotifier = ValueNotifier(null);

  final ScrollController scrollController = ScrollController();

  final updatePinnedMessagesInteractor =
      getIt.get<UpdatePinnedMessagesInteractor>();

  Room? get room => widget.pinnedEvents.first?.room;

  Client get client => Matrix.of(context).client;

  ValueNotifier<List<Event>> selectedEvents = ValueNotifier([]);

  List<String> get selectedPinnedEventsIds =>
      selectedEvents.value.map((event) => event.eventId).toList();

  final ValueNotifier<bool> openingPopupMenu = ValueNotifier(false);

  StreamSubscription<Either<Failure, Success>>? unpinMessagesStreamSubcription;

  StreamSubscription<Either<Failure, Success>>? unpinAllStreamSubcription;

  StreamSubscription<Either<Failure, Success>>?
      unpinSelectedEventsStreamSubcription;

  StreamSubscription<EventUpdate>? onEventStreamSubscription;

  void unpin(String eventId) {
    unpinMessagesStreamSubcription = updatePinnedMessagesInteractor
        .execute(room: room!, eventIds: [eventId]).listen((event) {
      event.fold((failure) {
        _showErrorSnackbar(failure);
      }, (success) {
        if (success is UpdatePinnedEventsSuccess) {
          _updateEventsNotifier(
            eventsNotifier.value
                .where((event) => event?.eventId != eventId)
                .toList(),
          );
          if (eventsNotifier.value.isEmpty) {
            Navigator.of(context).pop(eventsNotifier.value);
          }
        }
      });
    });
  }

  void unpinAll() {
    unpinAllStreamSubcription = updatePinnedMessagesInteractor
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
            _updateEventsNotifier([]);
            Navigator.of(context).pop();
          }
        },
      );
    });
  }

  void unpinSelectedEvents() {
    unpinSelectedEventsStreamSubcription = updatePinnedMessagesInteractor
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
              _updateEventsNotifier(
                eventsNotifier.value
                    .where(
                      (event) =>
                          !selectedPinnedEventsIds.contains(event?.eventId),
                    )
                    .toList(),
              );
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

  void onLongPressMessage(BuildContext context, Event event) {
    if (PinnedMessagesStyle.responsiveUtils.isMobile(context)) {
      _showMessageBottomSheet(event);
    }
  }

  void _showMessageBottomSheet(Event event) async {
    await showAdaptiveBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: getPinnedMessagesActionsList(event).map((action) {
            return popupItemByTwakeAppRouter(
              context,
              action.getTitle(
                context,
                unpin: event.isPinned,
                isSelected: isSelected(event),
              ),
              iconAction: action.getIconData(unpin: event.isPinned),
              imagePath: action.getImagePath(unpin: event.isPinned),
              colorIcon:
                  action == ChatContextMenuActions.pinChat && event.isPinned
                      ? Theme.of(context).colorScheme.onSurface
                      : null,
              onCallbackAction: () => _handleClickOnContextMenuItem(
                action,
                event,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _initPinnedEvents() {
    if (widget.pinnedEvents.isNotEmpty) {
      _updateEventsNotifier(widget.pinnedEvents);
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

  List<Widget> pinnedMessagesActionsList(
    BuildContext context,
    List<ChatContextMenuActions> actions,
    Event event,
  ) {
    return actions.map((action) {
      return popupItemByTwakeAppRouter(
        context,
        action.getTitle(
          context,
          unpin: event.isPinned,
          isSelected: isSelected(event),
        ),
        iconAction: action.getIconData(unpin: event.isPinned),
        imagePath: action.getImagePath(unpin: event.isPinned),
        colorIcon: action == ChatContextMenuActions.pinChat && event.isPinned
            ? Theme.of(context).colorScheme.onSurface
            : null,
        onCallbackAction: () => _handleClickOnContextMenuItem(
          action,
          event,
        ),
      );
    }).toList();
  }

  List<ChatContextMenuActions> getPinnedMessagesActionsList(Event event) {
    final listAction = [
      ChatContextMenuActions.pinChat,
      ChatContextMenuActions.select,
      ChatContextMenuActions.jumpToMessage,
      ChatContextMenuActions.copyMessage,
      ChatContextMenuActions.forward,
      if (PlatformInfos.isWeb && event.hasAttachment)
        ChatContextMenuActions.downloadFile,
    ];
    return listAction;
  }

  List<ContextMenuAction> pinnedMessagesContextMenuActionsList(
    BuildContext context,
    Event event,
  ) {
    final actionTiles = getPinnedMessagesActionsList(event).map((action) {
      return ContextMenuAction(
        name: action.getTitle(
          context,
          unpin: event.isPinned,
          isSelected: isSelected(event),
        ),
        icon: action.getIconData(unpin: event.isPinned),
        imagePath: action.getImagePath(unpin: event.isPinned),
        colorIcon: action == ChatContextMenuActions.pinChat && event.isPinned
            ? Theme.of(context).colorScheme.onSurface
            : null,
      );
    }).toList();
    return actionTiles;
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
      case ChatContextMenuActions.jumpToMessage:
        jumpToMessage(context, event);
        break;
      default:
        break;
    }
  }

  void jumpToMessage(BuildContext context, Event event) {
    context.go(
      '/rooms/${event.roomId}?event=${event.eventId}',
    );
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
  ) async {
    final offset = tapDownDetails.globalPosition;
    final listActions = pinnedMessagesContextMenuActionsList(context, event);
    _handleStateContextMenu();
    final selectedActionIndex = await showTwakeContextMenu(
      context: context,
      offset: offset,
      listActions: listActions,
      onClose: _handleStateContextMenu,
    );
    if (selectedActionIndex != null && selectedActionIndex is int) {
      _handleClickOnContextMenuItem(
        getPinnedMessagesActionsList(event)[selectedActionIndex],
        event,
      );
    }
  }

  void _listenRoomUpdateEvent() {
    if (room == null) return;
    onEventStreamSubscription = client.onEvent.stream.listen((eventUpdate) {
      Logs().d(
        'PinnedMessages::_listenRoomUpdateEvent():: Event Update Content ${eventUpdate.content}',
      );
      if (eventUpdate.isPinnedEventsHasChanged) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          eventUpdate.updatePinnedMessage(
            onPinnedMessageUpdated: ({
              required bool isInitial,
              required bool isUnpin,
              String? eventId,
            }) {
              _handlePinnedMessageCallBack();
            },
          );
        });
      }
    });
  }

  void _handlePinnedMessageCallBack() async {
    try {
      final result =
          (await Future.wait(room!.pinnedEventIds.map(room!.getEventById)))
              .nonNulls
              .toList();

      if (result.isNotEmpty) {
        _updateEventsNotifier(result);
      }

      if (eventsNotifier.value.isNotEmpty && result.isEmpty) {
        _updateEventsNotifier(result);
        Navigator.of(context).pop();
      }
    } on MatrixException catch (exception) {
      Logs().e(
        'PinnedMessages::_handlePinnedMessageCallBack():: ErrorCode ${exception.errcode}: ${exception.errorMessage}',
      );
    }
  }

  void _updateEventsNotifier(List<Event?> events) {
    eventsNotifier.value = events;
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initPinnedEvents();
      _listenRoomUpdateEvent();
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    isHoverNotifier.dispose();
    Future.wait([
      unpinAllStreamSubcription?.cancel() ?? Future.value(),
      unpinMessagesStreamSubcription?.cancel() ?? Future.value(),
      unpinSelectedEventsStreamSubcription?.cancel() ?? Future.value(),
      onEventStreamSubscription?.cancel() ?? Future.value(),
    ]).whenComplete(() => eventsNotifier.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PinnedMessagesScreen(this);
  }
}
