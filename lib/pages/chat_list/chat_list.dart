import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:collection/collection.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/first_column_inner_routes.dart';
import 'package:fluffychat/di/global/dio_cache_interceptor_for_client.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/pages/bootstrap/bootstrap_dialog.dart';
import 'package:fluffychat/pages/chat_list/chat_custom_slidable_action.dart';
import 'package:fluffychat/pages/chat_list/chat_list_view_style.dart';
import 'package:fluffychat/presentation/mixins/comparable_presentation_contact_mixin.dart';
import 'package:fluffychat/pages/bootstrap/tom_bootstrap_dialog.dart';
import 'package:fluffychat/pages/chat_list/chat_list_view.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_security/settings_security.dart';
import 'package:fluffychat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:fluffychat/presentation/extensions/client_extension.dart';
import 'package:fluffychat/presentation/mixins/go_to_group_chat_mixin.dart';
import 'package:fluffychat/presentation/model/chat_list/chat_selection_actions.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/utils/tor_stub.dart'
    if (dart.library.html) 'package:tor_detector_web/tor_detector_web.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action.dart';
import 'package:fluffychat/widgets/layouts/agruments/app_adaptive_scaffold_body_args.dart';
import 'package:fluffychat/widgets/layouts/agruments/logged_in_body_args.dart';
import 'package:fluffychat/widgets/layouts/agruments/logged_in_other_account_body_args.dart';
import 'package:fluffychat/widgets/mixins/popup_context_menu_action_mixin.dart';
import 'package:fluffychat/widgets/mixins/popup_menu_widget_mixin.dart';
import 'package:fluffychat/widgets/mixins/twake_context_menu_mixin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import '../../../utils/account_bundles.dart';
import '../../widgets/matrix.dart';

class ChatList extends StatefulWidget {
  static BuildContext? contextForVoip;

  final ValueNotifier<String?> activeRoomIdNotifier;

  final Widget? bottomNavigationBar;

  final VoidCallback? onOpenSettings;

  final AbsAppAdaptiveScaffoldBodyArgs? adaptiveScaffoldBodyArgs;

  const ChatList({
    super.key,
    required this.activeRoomIdNotifier,
    this.bottomNavigationBar,
    this.onOpenSettings,
    this.adaptiveScaffoldBodyArgs,
  });

  @override
  ChatListController createState() => ChatListController();
}

class ChatListController extends State<ChatList>
    with
        AutomaticKeepAliveClientMixin,
        TickerProviderStateMixin,
        RouteAware,
        ComparablePresentationContactMixin,
        PopupContextMenuActionMixin,
        PopupMenuWidgetMixin,
        GoToGroupChatMixin,
        TwakeContextMenuMixin {
  final responsive = getIt.get<ResponsiveUtils>();

  final ValueNotifier<bool> expandRoomsForAllNotifier = ValueNotifier(true);

  final ValueNotifier<bool> expandRoomsForPinNotifier = ValueNotifier(true);

  final ValueNotifier<SelectMode> selectModeNotifier =
      ValueNotifier(SelectMode.normal);

  final ValueNotifier<List<ConversationSelectionPresentation>>
      conversationSelectionNotifier = ValueNotifier([]);

  final TextEditingController searchChatController = TextEditingController();

  final ScrollController scrollController = ScrollController();

  final StreamController<Client> _clientStream = StreamController.broadcast();

  String? activeSpaceId;

  Future<QueryPublicRoomsResponse>? publicRoomsResponse;

  SearchUserDirectoryResponse? userSearchResult;

  QueryPublicRoomsResponse? roomSearchResult;

  bool isTorBrowser = false;

  bool scrolledToTop = true;

  Client get activeClient => matrixState.client;

  MatrixState get matrixState => Matrix.of(context);

  ActiveFilter activeFilter = AppConfig.separateChatTypes
      ? ActiveFilter.messages
      : ActiveFilter.allChats;

  List<Room> get _filteredRooms =>
      activeClient.filteredRoomsForAll(activeFilter);

  List<Room> get filteredRoomsForAll =>
      _filteredRooms.where((room) => !room.isFavourite).toList();

  List<Room> get filteredRoomsForPin =>
      _filteredRooms.where((room) => room.isFavourite).toList();

  bool get displayNavigationBar => false;

  Stream<Client> get clientStream => _clientStream.stream;

  // Needs to match GroupsSpacesEntry for 'separate group' checking.
  List<Room> get spaces => activeClient.rooms.where((r) => r.isSpace).toList();

  ValueNotifier<String?> activeRoomIdNotifier = ValueNotifier(null);

  bool get isSelectMode => selectModeNotifier.value == SelectMode.select;

  bool get anySelectedRoomNotMarkedUnread =>
      conversationSelectionNotifier.value.any(
        (conversation) => !Matrix.of(context)
            .client
            .getRoomById(conversation.roomId)!
            .isUnreadOrInvited,
      );

  bool get anySelectedRoomNotFavorite =>
      conversationSelectionNotifier.value.any(
        (conversation) => !Matrix.of(context)
            .client
            .getRoomById(conversation.roomId)!
            .isFavourite,
      );

  bool get anySelectedRoomNotMuted => conversationSelectionNotifier.value.any(
        (conversation) =>
            Matrix.of(context)
                .client
                .getRoomById(conversation.roomId)!
                .pushRuleState ==
            PushRuleState.notify,
      );

  bool get displayBundles =>
      Matrix.of(context).hasComplexBundles &&
      Matrix.of(context).accountBundles.keys.length > 1;

  bool get filteredRoomsForAllIsEmpty => filteredRoomsForAll.isEmpty;

  bool get filteredRoomsForPinIsEmpty => filteredRoomsForPin.isEmpty;

  bool get chatListBodyIsEmpty =>
      filteredRoomsForAllIsEmpty && filteredRoomsForPinIsEmpty;

  bool get conversationSelectionNotifierIsEmpty =>
      conversationSelectionNotifier.value.isEmpty;

  PushRuleState get pushRuleState => anySelectedRoomNotMuted
      ? PushRuleState.mentionsOnly
      : PushRuleState.notify;

  void addAccountAction() => context.go('/settings/account');

  void _onScroll() {
    final newScrolledToTop = scrollController.position.pixels <= 0;
    if (newScrolledToTop != scrolledToTop) {
      setState(() {
        scrolledToTop = newScrolledToTop;
      });
    }
  }

  void editSpace(BuildContext context, String spaceId) async {
    await activeClient.getRoomById(spaceId)!.postLoad();
    if (mounted) {
      context.go('/spaces/$spaceId');
    }
  }

  String? get secureActiveBundle {
    if (Matrix.of(context).activeBundle == null ||
        !Matrix.of(context)
            .accountBundles
            .keys
            .contains(Matrix.of(context).activeBundle)) {
      return Matrix.of(context).accountBundles.keys.first;
    }
    return Matrix.of(context).activeBundle;
  }

  void toggleSelection(String roomId) {
    final conversation = conversationSelectionNotifier.value.firstWhereOrNull(
      (conversation) => conversation.roomId == roomId,
    );

    final Set<ConversationSelectionPresentation>
        tempConversationSelectionPresentation =
        conversationSelectionNotifier.value.toSet();

    if (conversation != null && conversation.isSelected) {
      tempConversationSelectionPresentation.remove(conversation);
      if (tempConversationSelectionPresentation.isEmpty) {
        toggleSelectMode();
      }
    } else {
      tempConversationSelectionPresentation.add(
        ConversationSelectionPresentation(
          roomId: roomId,
          selectionType: SelectionType.selected,
        ),
      );
    }

    conversationSelectionNotifier.value =
        tempConversationSelectionPresentation.toList();
  }

  void toggleSelectMode() {
    selectModeNotifier.value =
        isSelectMode ? SelectMode.normal : SelectMode.select;
    _clearSelectionItem();
  }

  Future<void> actionWithToggleSelectMode(Function action) async {
    await action();
    toggleSelectMode();
  }

  void _clearSelectionItem() {
    conversationSelectionNotifier.value = [];
  }

  void onClickClearSelection() {
    toggleSelectMode();
  }

  void resetActiveSpaceId() {
    setState(() {
      activeSpaceId = null;
    });
  }

  void setActiveSpace(String? spaceId) {
    setState(() {
      activeSpaceId = spaceId;
    });
  }

  Future<void> toggleUnreadSelections() async {
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        final markUnreadAction = anySelectedRoomNotMarkedUnread;
        for (final conversation in conversationSelectionNotifier.value) {
          final room = activeClient.getRoomById(conversation.roomId)!;
          if (room.markedUnread == markUnreadAction) {
            if (room.isUnread) {
              await room.setReadMarker(
                room.lastEvent!.eventId,
                mRead: room.lastEvent!.eventId,
              );
            }
          }

          await room.markUnread(markUnreadAction);
        }
      },
    );
  }

  Future<void> toggleFavouriteRoom() async {
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        final makeFavorite = anySelectedRoomNotFavorite;
        for (final conversation in conversationSelectionNotifier.value) {
          final room = activeClient.getRoomById(conversation.roomId)!;
          if (room.isFavourite == makeFavorite) continue;
          await activeClient
              .getRoomById(conversation.roomId)!
              .setFavourite(makeFavorite);
        }
      },
    );
  }

  Future<void> toggleMutedSelections() async {
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        final newRuleState = pushRuleState;
        for (final conversation in conversationSelectionNotifier.value) {
          final room = activeClient.getRoomById(conversation.roomId)!;
          if (room.pushRuleState == newRuleState) continue;
          await activeClient
              .getRoomById(conversation.roomId)!
              .setPushRuleState(newRuleState);
        }
      },
    );
  }

  Future<void> archiveAction() async {
    final confirmed = await showOkCancelAlertDialog(
          useRootNavigator: false,
          context: context,
          title: L10n.of(context)!.areYouSure,
          okLabel: L10n.of(context)!.yes,
          cancelLabel: L10n.of(context)!.cancel,
        ) ==
        OkCancelResult.ok;
    if (!confirmed) return;
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () => _archiveSelectedRooms(),
    );
    setState(() {});
  }

  void setStatus() async {
    final input = await showTextInputDialog(
      useRootNavigator: false,
      context: context,
      title: L10n.of(context)!.setStatus,
      okLabel: L10n.of(context)!.ok,
      cancelLabel: L10n.of(context)!.cancel,
      textFields: [
        DialogTextField(
          hintText: L10n.of(context)!.statusExampleMessage,
        ),
      ],
    );
    if (input == null) return;
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () => activeClient.setPresence(
        activeClient.userID!,
        PresenceType.online,
        statusMsg: input.single,
      ),
    );
  }

  Future<void> _archiveSelectedRooms() async {
    while (conversationSelectionNotifier.value.isNotEmpty) {
      final conversation = conversationSelectionNotifier.value.first;
      try {
        await activeClient.getRoomById(conversation.roomId)!.leave();
      } finally {
        toggleSelection(conversation.roomId);
      }
    }
  }

  Future<void> addToSpace() async {
    final selectedSpace = await showConfirmationDialog<String>(
      context: context,
      title: L10n.of(context)!.addToSpace,
      message: L10n.of(context)!.addToSpaceDescription,
      fullyCapitalizedForMaterial: false,
      actions: Matrix.of(context)
          .client
          .rooms
          .where((r) => r.isSpace)
          .map(
            (space) => AlertDialogAction(
              key: space.id,
              label: space
                  .getLocalizedDisplayname(MatrixLocals(L10n.of(context)!)),
            ),
          )
          .toList(),
    );
    if (selectedSpace == null) return;
    final result = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        final space = activeClient.getRoomById(selectedSpace)!;
        if (space.canSendDefaultStates) {
          for (final conversation in conversationSelectionNotifier.value) {
            await space.setSpaceChild(conversation.roomId);
          }
        }
      },
    );
    if (result.error == null) {
      if (!mounted) return;
      TwakeSnackBar.show(
        context,
        L10n.of(context)!.chatHasBeenAddedToThisSpace,
      );
    }

    conversationSelectionNotifier.value.clear();
  }

  Future<void> setupAdditionalDioCacheOption(String userId) async {
    Logs().d('ChatList::setupAdditionalDioCacheOption: $userId');
    DioCacheInterceptorForClient(userId).setup(getIt);
  }

  Future<void> _trySync() async {
    if (widget.adaptiveScaffoldBodyArgs is LoggedInBodyArgs ||
        widget.adaptiveScaffoldBodyArgs is LoggedInOtherAccountBodyArgs) {
      _waitForFirstSyncAfterLogin();
    } else {
      _waitForFirstSync();
    }
  }

  Future<void> _waitForFirstSyncAfterLogin() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await TomBootstrapDialog(
        client: activeClient,
      ).show(context);

      setState(() {});

      if (result == false) {
        await BootstrapDialog(client: activeClient).show();
      }
    });

    if (!mounted) return;
    setState(() {
      matrixState.waitForFirstSync = true;
    });
  }

  Future<void> _waitForFirstSync() async {
    await activeClient.roomsLoading;
    await activeClient.accountDataLoading;
    if (activeClient.userID != null) {
      await setupAdditionalDioCacheOption(activeClient.userID!);
    }
    if (!mounted) return;
    setState(() {
      matrixState.waitForFirstSync = true;
    });
  }

  void setActiveBundle(String bundle) {
    context.go('/rooms');
    setState(() {
      conversationSelectionNotifier.value.clear();
      Matrix.of(context).activeBundle = bundle;
      if (!Matrix.of(context)
          .currentBundle!
          .any((client) => client == client)) {
        Matrix.of(context)
            .setActiveClient(Matrix.of(context).currentBundle!.first);
      }
    });
  }

  void editBundlesForAccount(String? userId, String? activeBundle) async {
    final l10n = L10n.of(context)!;
    final client = Matrix.of(context)
        .widget
        .clients[Matrix.of(context).getClientIndexByMatrixId(userId!)];
    final action = await showConfirmationDialog<EditBundleAction>(
      context: context,
      title: L10n.of(context)!.editBundlesForAccount,
      actions: [
        AlertDialogAction(
          key: EditBundleAction.addToBundle,
          label: L10n.of(context)!.addToBundle,
        ),
        if (activeBundle != client.userID)
          AlertDialogAction(
            key: EditBundleAction.removeFromBundle,
            label: L10n.of(context)!.removeFromBundle,
          ),
      ],
    );
    if (action == null) return;
    switch (action) {
      case EditBundleAction.addToBundle:
        final bundle = await showTextInputDialog(
          context: context,
          title: l10n.bundleName,
          textFields: [DialogTextField(hintText: l10n.bundleName)],
        );
        if (bundle == null || bundle.isEmpty || bundle.single.isEmpty) return;
        await TwakeDialog.showFutureLoadingDialogFullScreen(
          future: () => client.setAccountBundle(bundle.single),
        );
        break;
      case EditBundleAction.removeFromBundle:
        await TwakeDialog.showFutureLoadingDialogFullScreen(
          future: () => client.removeFromAccountBundle(activeBundle!),
        );
    }
  }

  void _onTapBottomNavigation(
    ChatListSelectionActions chatListBottomNavigatorBar,
  ) async {
    switch (chatListBottomNavigatorBar) {
      case ChatListSelectionActions.read:
        await actionWithToggleSelectMode(toggleUnreadSelections);
        return;
      case ChatListSelectionActions.mute:
        await actionWithToggleSelectMode(toggleMutedSelections);
        return;
      case ChatListSelectionActions.pin:
        await actionWithToggleSelectMode(toggleFavouriteRoom);
        return;
      case ChatListSelectionActions.more:
        await actionWithToggleSelectMode(
          () => {
            TwakeSnackBar.show(context, 'Not implemented yet'),
          },
        );
        return;
    }
  }

  void handleContextMenuAction(
    BuildContext context,
    Room room,
    TapDownDetails details,
  ) async {
    disableRightClick();
    final offset = details.globalPosition;
    final listPopupActions = _popupMenuActions(room);
    final listContextActions = _mapPopupMenuActionsToContextMenuActions(
      context,
      room,
      listPopupActions,
    );
    final selectedActionIndex = await showTwakeContextMenu(
      offset: offset,
      context: context,
      listActions: listContextActions,
    );
    enableRightClick();
    if (selectedActionIndex != null && selectedActionIndex is int) {
      _handleClickOnContextMenuItem(
        listPopupActions[selectedActionIndex],
        room,
      );
    }
  }

  List<ChatListSelectionActions> _popupMenuActions(Room room) {
    final listAction = [
      if (!room.isInvitation) ...[
        ChatListSelectionActions.read,
        ChatListSelectionActions.pin,
      ],
      ChatListSelectionActions.mute,
    ];
    return listAction;
  }

  List<ContextMenuAction> _mapPopupMenuActionsToContextMenuActions(
    BuildContext context,
    Room room,
    List<ChatListSelectionActions> listActions,
  ) {
    return listActions.map((action) {
      return ContextMenuAction(
        name: action.getTitleContextMenuSelection(context, room),
        icon: action.getIconContextMenuSelection(room),
      );
    }).toList();
  }

  void _handleClickOnContextMenuItem(
    ChatListSelectionActions action,
    Room room,
  ) async {
    switch (action) {
      case ChatListSelectionActions.read:
        await toggleRead(room);
        return;
      case ChatListSelectionActions.pin:
        await togglePin(room);
        return;
      case ChatListSelectionActions.mute:
        await toggleMuteRoom(room);
        return;
      case ChatListSelectionActions.more:
        return;
    }
  }

  Future<void> toggleRead(Room room) async {
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        if (room.isUnread) {
          await room.markUnread(false);
          await room.setReadMarker(
            room.lastEvent!.eventId,
            mRead: room.lastEvent!.eventId,
          );
        } else {
          await room.markUnread(true);
        }
      },
    );
  }

  Future<void> togglePin(Room room) async {
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        await room.setFavourite(!room.isFavourite);
      },
    );
  }

  Future<void> toggleMuteRoom(Room room) async {
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        if (room.isMuted) {
          await room.unmute();
        } else {
          await room.mute();
        }
      },
    );
  }

  List<ChatListSelectionActions> _getNavigationDestinations() {
    return [
      ChatListSelectionActions.read,
      ChatListSelectionActions.mute,
      ChatListSelectionActions.pin,
      //TODO: Enable when more action is implemented
      // ChatListSelectionActions.more,
    ];
  }

  List<Widget> bottomNavigationActionsWidget({
    required EdgeInsetsDirectional paddingIcon,
    double? width,
    double? iconSize,
  }) {
    return _getNavigationDestinations().map((item) {
      return InkWell(
        onTap: () => _onTapBottomNavigation(item),
        child: SizedBox(
          width: width,
          child: Column(
            children: [
              Padding(
                padding: paddingIcon,
                child: Icon(
                  item.getIconBottomNavigation(),
                  size: iconSize,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                _getTitleBottomNavigation(item),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  String _getTitleBottomNavigation(
    ChatListSelectionActions actionBottomNavigation,
  ) {
    switch (actionBottomNavigation) {
      case ChatListSelectionActions.read:
        if (anySelectedRoomNotMarkedUnread) {
          return L10n.of(context)!.unread;
        } else {
          return L10n.of(context)!.read;
        }
      case ChatListSelectionActions.mute:
        if (anySelectedRoomNotMuted) {
          return L10n.of(context)!.mute;
        } else {
          return L10n.of(context)!.unmute;
        }
      case ChatListSelectionActions.pin:
        if (anySelectedRoomNotFavorite) {
          return L10n.of(context)!.pin;
        } else {
          return L10n.of(context)!.unpin;
        }
      case ChatListSelectionActions.more:
        return L10n.of(context)!.more;
    }
  }

  void _hackyWebRTCFixForWeb() {
    ChatList.contextForVoip = context;
  }

  Future<void> _checkTorBrowser() async {
    if (!kIsWeb) return;
    final isTor = await TorBrowserDetector.isTorBrowser;
    isTorBrowser = isTor;
  }

  Future<void> dehydrate() =>
      SettingsSecurityController.dehydrateDevice(context);

  void onLongPressChatListItem(Room room) {
    if (!isSelectMode) {
      toggleSelectMode();
      _handleOnLongPressInSelectMode(room);
    }
  }

  void _handleOnLongPressInSelectMode(Room room) {
    if (conversationSelectionNotifierIsEmpty) {
      toggleSelection(
        room.id,
      );
    }
  }

  void goToNewPrivateChat() {
    if (FirstColumnInnerRoutes.instance.goRouteAvailableInFirstColumn()) {
      context.go('/rooms/newprivatechat');
    } else {
      context.pushInner('innernavigator/newprivatechat');
    }
  }

  void onClickAvatar() {
    context.push('/rooms/profile');
  }

  void _handleRecovery() {
    if (widget.adaptiveScaffoldBodyArgs is LoggedInOtherAccountBodyArgs) {
      Logs().d(
        "ChatList::_handleAnotherAccountAdded(): Handle recovery data for another account",
      );
      if (!matrixState.waitForFirstSync) {
        _trySync();
      }
    }
  }

  @override
  void didUpdateWidget(covariant ChatList oldWidget) {
    Logs().d(
      "ChatList::didUpdateWidget(): Old Args ${oldWidget.adaptiveScaffoldBodyArgs} - UserId ${oldWidget.adaptiveScaffoldBodyArgs?.newActiveClient?.userID}",
    );
    final newActiveClient = widget.adaptiveScaffoldBodyArgs?.newActiveClient;
    Logs().d(
      "ChatList::didUpdateWidget(): New Args ${widget.adaptiveScaffoldBodyArgs} - UserId ${newActiveClient?.userID}",
    );
    if (newActiveClient != null && newActiveClient.userID != null) {
      setState(() {
        _clientStream.add(newActiveClient);
        _handleRecovery();
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    activeRoomIdNotifier.value = widget.activeRoomIdNotifier.value;
    scrollController.addListener(_onScroll);
    if (!matrixState.waitForFirstSync) {
      _trySync();
    }
    _hackyWebRTCFixForWeb();
    // TODO: 28Dec2023 Disable callkeep for util we support audio/video calls
    // CallKeepManager().initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        Matrix.of(context).backgroundPush?.setupPush();
      }
    });
    _checkTorBrowser();
    super.initState();
  }

  void onOpenSearchPageInMultipleColumns() {
    if (!FirstColumnInnerRoutes.instance.goRouteAvailableInFirstColumn()) {
      context.pushInner('innernavigator/search');
    }
  }

  List<Widget> getSlidables(BuildContext context, Room room) {
    return [
      if (!room.isInvitation)
        ChatCustomSlidableAction(
          label:
              room.isUnread ? L10n.of(context)!.read : L10n.of(context)!.unread,
          icon: Icon(
            room.isUnread
                ? Icons.mark_chat_read_outlined
                : Icons.mark_chat_unread_outlined,
            size: ChatListViewStyle.slidableIconSize,
          ),
          onPressed: (_) => toggleRead(room),
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          backgroundColor: ChatListViewStyle.readSlidableColor(room.isUnread)!,
        ),
      ChatCustomSlidableAction(
        label: room.isMuted ? L10n.of(context)!.unmute : L10n.of(context)!.mute,
        icon: Icon(
          room.isMuted
              ? Icons.notifications_on_outlined
              : Icons.notifications_off_outlined,
          size: ChatListViewStyle.slidableIconSize,
        ),
        onPressed: (_) => toggleMuteRoom(room),
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: ChatListViewStyle.muteSlidableColor(room.isMuted)!,
      ),
      if (!room.isInvitation)
        ChatCustomSlidableAction(
          label: room.isFavourite
              ? L10n.of(context)!.unpin
              : L10n.of(context)!.pin,
          icon: room.isFavourite
              ? SvgPicture.asset(
                  ImagePaths.icUnpin,
                  width: ChatListViewStyle.slidableIconSize,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onPrimary,
                    BlendMode.srcIn,
                  ),
                )
              : const Icon(
                  Icons.push_pin_outlined,
                  size: ChatListViewStyle.slidableIconSize,
                ),
          onPressed: (_) => togglePin(room),
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          backgroundColor:
              ChatListViewStyle.pinSlidableColor(room.isFavourite)!,
        ),
    ];
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChatListView(
      controller: this,
      bottomNavigationBar: widget.bottomNavigationBar,
      onOpenSearchPageInMultipleColumns: onOpenSearchPageInMultipleColumns,
      onTapBottomNavigation: _onTapBottomNavigation,
    );
  }

  @override
  bool get wantKeepAlive => true;
}

enum EditBundleAction { addToBundle, removeFromBundle }
