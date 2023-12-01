import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:collection/collection.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/first_column_inner_routes.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/recovery_words/recovery_words.dart';
import 'package:fluffychat/domain/usecase/recovery/get_recovery_words_interactor.dart';
import 'package:fluffychat/presentation/mixins/comparable_presentation_contact_mixin.dart';
import 'package:fluffychat/pages/bootstrap/bootstrap_dialog.dart';
import 'package:fluffychat/pages/bootstrap/tom_bootstrap_dialog.dart';
import 'package:fluffychat/pages/chat_list/chat_list_view.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_security/settings_security.dart';
import 'package:fluffychat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:fluffychat/presentation/extensions/client_extension.dart';
import 'package:fluffychat/presentation/mixins/go_to_group_chat_mixin.dart';
import 'package:fluffychat/presentation/model/chat_list/chat_selection_actions.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/utils/tor_stub.dart'
    if (dart.library.html) 'package:tor_detector_web/tor_detector_web.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/mixins/popup_context_menu_action_mixin.dart';
import 'package:fluffychat/widgets/mixins/popup_menu_widget_mixin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import '../../../utils/account_bundles.dart';
import '../../utils/voip/callkeep_manager.dart';
import '../../widgets/matrix.dart';

class ChatList extends StatefulWidget {
  static BuildContext? contextForVoip;

  final ValueNotifier<String?> activeRoomIdNotifier;

  final Widget? bottomNavigationBar;

  final VoidCallback? onOpenSearchPage;

  const ChatList({
    Key? key,
    required this.activeRoomIdNotifier,
    this.bottomNavigationBar,
    this.onOpenSearchPage,
  }) : super(key: key);

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
        GoToGroupChatMixin {
  final _getRecoveryWordsInteractor = getIt.get<GetRecoveryWordsInteractor>();

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

  bool waitForFirstSync = false;

  bool scrolledToTop = true;

  Client get client => Matrix.of(context).client;

  ActiveFilter activeFilter = AppConfig.separateChatTypes
      ? ActiveFilter.messages
      : ActiveFilter.allChats;

  List<Room> get _filteredRooms => client.filteredRoomsForAll(activeFilter);

  List<Room> get filteredRoomsForAll =>
      _filteredRooms.where((room) => !room.isFavourite).toList();

  List<Room> get filteredRoomsForPin =>
      _filteredRooms.where((room) => room.isFavourite).toList();

  bool get displayNavigationBar => false;

  Stream<Client> get clientStream => _clientStream.stream;

  // Needs to match GroupsSpacesEntry for 'separate group' checking.
  List<Room> get spaces => client.rooms.where((r) => r.isSpace).toList();

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
    await client.getRoomById(spaceId)!.postLoad();
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
  }

  Future<void> actionWithToggleSelectMode(Function action) async {
    await action();
    toggleSelectMode();
    _clearSelectionItem();
  }

  void _clearSelectionItem() {
    conversationSelectionNotifier.value = [];
  }

  void onClickClearSelection() {
    if (conversationSelectionNotifier.value.isNotEmpty) {
      _clearSelectionItem();
    } else {
      toggleSelectMode();
    }
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

  Future<void> toggleUnread() async {
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        final markUnread = anySelectedRoomNotMarkedUnread;
        for (final conversation in conversationSelectionNotifier.value) {
          final room = client.getRoomById(conversation.roomId)!;
          if (room.markedUnread == markUnread) continue;
          await client.getRoomById(conversation.roomId)!.markUnread(markUnread);
        }
      },
    );
  }

  Future<void> toggleFavouriteRoom() async {
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        final makeFavorite = anySelectedRoomNotFavorite;
        for (final conversation in conversationSelectionNotifier.value) {
          final room = client.getRoomById(conversation.roomId)!;
          if (room.isFavourite == makeFavorite) continue;
          await client
              .getRoomById(conversation.roomId)!
              .setFavourite(makeFavorite);
        }
      },
    );
  }

  Future<void> toggleMuted() async {
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        for (final conversation in conversationSelectionNotifier.value) {
          final room = client.getRoomById(conversation.roomId)!;
          if (room.pushRuleState == pushRuleState) continue;
          await client
              .getRoomById(conversation.roomId)!
              .setPushRuleState(pushRuleState);
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
      future: () => client.setPresence(
        client.userID!,
        PresenceType.online,
        statusMsg: input.single,
      ),
    );
  }

  Future<void> _archiveSelectedRooms() async {
    while (conversationSelectionNotifier.value.isNotEmpty) {
      final conversation = conversationSelectionNotifier.value.first;
      try {
        await client.getRoomById(conversation.roomId)!.leave();
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
        final space = client.getRoomById(selectedSpace)!;
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

  Future<void> _waitForFirstSync() async {
    await client.roomsLoading;
    await client.accountDataLoading;
    if (client.prevBatch == null) {
      await client.onSync.stream.first;
      await client.initCompleter?.future;

      // Display first login bootstrap if enabled
      if (client.encryption?.keyManager.enabled == true) {
        Logs().d(
          'ChatList::_waitForFirstSync: Showing bootstrap dialog when encryption is enabled',
        );
        if (await client.encryption?.keyManager.isCached() == false ||
            await client.encryption?.crossSigning.isCached() == false ||
            client.isUnknownSession && mounted) {
          final recoveryWords = await _getRecoveryWords();
          if (recoveryWords != null) {
            await TomBootstrapDialog(
              client: client,
              recoveryWords: recoveryWords,
            ).show();
          } else {
            Logs().d(
              'ChatListController::_waitForFirstSync(): no recovery existed then call bootstrap',
            );
            await BootstrapDialog(client: client).show();
          }
        }
      } else {
        Logs().d(
          'ChatListController::_waitForFirstSync(): encryption is not enabled',
        );
        final recoveryWords = await _getRecoveryWords();
        await TomBootstrapDialog(
          client: client,
          wipeRecovery: recoveryWords != null,
        ).show();
      }
    }
    if (!mounted) return;
    setState(() {
      waitForFirstSync = true;
    });
  }

  void setActiveClient(Client client) {
    context.go('/rooms');
    setState(() {
      activeFilter = AppConfig.separateChatTypes
          ? ActiveFilter.messages
          : ActiveFilter.allChats;
      activeSpaceId = null;
      conversationSelectionNotifier.value.clear();
      Matrix.of(context).setActiveClient(client);
    });
    _clientStream.add(client);
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
        await actionWithToggleSelectMode(toggleUnread);
        return;
      case ChatListSelectionActions.mute:
        await actionWithToggleSelectMode(toggleMuted);
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
  ) {
    openPopupMenuAction(
      context,
      context.getCurrentRelativeRectOfWidget(),
      _popupMenuActionTile(context, room),
    );
  }

  List<PopupMenuItem> _popupMenuActionTile(
    BuildContext context,
    Room room,
  ) {
    final listAction = [
      if (room.membership != Membership.invite) ...[
        ChatListSelectionActions.read,
        ChatListSelectionActions.pin,
      ],
      ChatListSelectionActions.mute,
    ];
    return listAction.map((action) {
      return PopupMenuItem(
        padding: EdgeInsets.zero,
        child: popupItemByNavigator(
          context,
          action.getTitleContextMenuSelection(context, room),
          iconAction: action.getIconContextMenuSelection(room),
          onCallbackAction: () => _handleClickOnContextMenuItem(
            action,
            room,
          ),
        ),
      );
    }).toList();
  }

  void _handleClickOnContextMenuItem(
    ChatListSelectionActions action,
    Room room,
  ) async {
    switch (action) {
      case ChatListSelectionActions.read:
        await TwakeDialog.showFutureLoadingDialogFullScreen(
          future: () async {
            await client.getRoomById(room.id)!.markUnread(!room.markedUnread);
          },
        );
        return;
      case ChatListSelectionActions.pin:
        await TwakeDialog.showFutureLoadingDialogFullScreen(
          future: () async {
            await client.getRoomById(room.id)!.setFavourite(!room.isFavourite);
          },
        );
        return;
      case ChatListSelectionActions.mute:
        await TwakeDialog.showFutureLoadingDialogFullScreen(
          future: () async {
            await client.getRoomById(room.id)!.setPushRuleState(
                  room.pushRuleState == PushRuleState.notify
                      ? PushRuleState.mentionsOnly
                      : PushRuleState.notify,
                );
          },
        );
        return;
      case ChatListSelectionActions.more:
        return;
    }
  }

  List<ChatListSelectionActions> _getNavigationDestinations() {
    return [
      ChatListSelectionActions.read,
      ChatListSelectionActions.mute,
      ChatListSelectionActions.pin,
      ChatListSelectionActions.more,
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

  Future<RecoveryWords?> _getRecoveryWords() async {
    return await _getRecoveryWordsInteractor.execute().then(
          (either) => either.fold(
            (failure) => null,
            (success) => success.words,
          ),
        );
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

  @override
  void initState() {
    if (kIsWeb) {
      BrowserContextMenu.disableContextMenu();
    }
    activeRoomIdNotifier.value = widget.activeRoomIdNotifier.value;
    scrollController.addListener(_onScroll);
    _waitForFirstSync();
    _hackyWebRTCFixForWeb();
    CallKeepManager().initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        Matrix.of(context).backgroundPush?.setupPush();
      }
    });

    _checkTorBrowser();
    super.initState();
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
      onOpenSearchPage: widget.onOpenSearchPage,
      onTapBottomNavigation: _onTapBottomNavigation,
    );
  }

  @override
  bool get wantKeepAlive => true;
}

enum EditBundleAction { addToBundle, removeFromBundle }
