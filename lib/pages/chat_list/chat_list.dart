import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/recovery_words/recovery_words.dart';
import 'package:fluffychat/domain/usecase/recovery/get_recovery_words_interactor.dart';
import 'package:fluffychat/mixin/comparable_presentation_contact_mixin.dart';
import 'package:fluffychat/pages/bootstrap/bootstrap_dialog.dart';
import 'package:fluffychat/pages/bootstrap/tom_bootstrap_dialog.dart';
import 'package:fluffychat/pages/chat_list/chat_list_view.dart';
import 'package:fluffychat/pages/chat_list/receive_sharing_intent_mixin.dart';
import 'package:fluffychat/pages/settings_security/settings_security.dart';
import 'package:fluffychat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:fluffychat/presentation/model/chat_list/chat_selection_actions.dart';
import 'package:fluffychat/utils/famedlysdk_store.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/client_stories_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/tor_stub.dart'
    if (dart.library.html) 'package:tor_detector_web/tor_detector_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import '../../../utils/account_bundles.dart';
import '../../utils/voip/callkeep_manager.dart';
import '../../widgets/matrix.dart';

class ChatList extends StatefulWidget {
  static BuildContext? contextForVoip;

  final String? activeRoomId;

  final Widget? bottomNavigationBar;

  final VoidCallback? onOpenSearchPage;

  const ChatList({
    Key? key,
    this.activeRoomId,
    this.bottomNavigationBar,
    this.onOpenSearchPage,
  }) : super(key: key);

  @override
  ChatListController createState() => ChatListController();
}

class ChatListController extends State<ChatList>
    with
        TickerProviderStateMixin,
        RouteAware,
        ComparablePresentationContactMixin,
        ReceiveSharingIntentMixin {
  final _getRecoveryWordsInteractor = getIt.get<GetRecoveryWordsInteractor>();

  bool get displayNavigationBar => false;

  String? activeSpaceId;

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

  ActiveFilter activeFilter = AppConfig.separateChatTypes
      ? ActiveFilter.messages
      : ActiveFilter.allChats;

  bool Function(Room) getRoomFilterByActiveFilter(ActiveFilter activeFilter) {
    switch (activeFilter) {
      case ActiveFilter.allChats:
        return (room) => !room.isSpace && !room.isStoryRoom;
      case ActiveFilter.groups:
        return (room) =>
            !room.isSpace && !room.isDirectChat && !room.isStoryRoom;
      case ActiveFilter.messages:
        return (room) =>
            !room.isSpace && room.isDirectChat && !room.isStoryRoom;
      case ActiveFilter.spaces:
        return (r) => r.isSpace;
    }
  }

  List<Room> get filteredRoomsForAll => Matrix.of(context)
      .client
      .rooms
      .where(getRoomFilterByActiveFilter(activeFilter))
      .toList();

  bool isSearchMode = false;
  Future<QueryPublicRoomsResponse>? publicRoomsResponse;
  String? searchServer;
  Timer? _coolDown;
  SearchUserDirectoryResponse? userSearchResult;
  QueryPublicRoomsResponse? roomSearchResult;

  final ValueNotifier<SelectMode> selectModeNotifier =
      ValueNotifier(SelectMode.normal);

  final ValueNotifier<List<ConversationSelectionPresentation>>
      conversationSelectionNotifier = ValueNotifier([]);

  bool isSearching = false;
  static const String _serverStoreNamespace = 'im.fluffychat.search.server';

  final TextEditingController searchChatController = TextEditingController();

  void _search() async {
    final client = Matrix.of(context).client;
    if (!isSearching) {
      setState(() {
        isSearching = true;
      });
    }
    SearchUserDirectoryResponse? userSearchResult;
    QueryPublicRoomsResponse? roomSearchResult;
    try {
      roomSearchResult = await client.queryPublicRooms(
        server: searchServer,
        filter: PublicRoomQueryFilter(
          genericSearchTerm: searchChatController.text,
        ),
        limit: 20,
      );
      userSearchResult = await client.searchUserDirectory(
        searchChatController.text,
        limit: 20,
      );
    } catch (e, s) {
      Logs().w('Searching has crashed', e, s);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toLocalizedString(context),
          ),
        ),
      );
    }
    if (!isSearchMode) return;
    setState(() {
      isSearching = false;
      this.roomSearchResult = roomSearchResult;
      this.userSearchResult = userSearchResult;
    });
  }

  void onSearchEnter(String text) {
    if (text.isEmpty) {
      cancelSearch(unfocus: false);
      return;
    }

    setState(() {
      isSearchMode = true;
    });
    _coolDown?.cancel();
    _coolDown = Timer(const Duration(milliseconds: 500), _search);
  }

  void cancelSearch({bool unfocus = true}) {
    setState(() {
      searchChatController.clear();
      isSearchMode = false;
      roomSearchResult = userSearchResult = null;
      isSearching = false;
    });
    if (unfocus) FocusManager.instance.primaryFocus?.unfocus();
  }

  bool isTorBrowser = false;

  BoxConstraints? snappingSheetContainerSize;

  final ScrollController scrollController = ScrollController();
  bool scrolledToTop = true;

  final StreamController<Client> _clientStream = StreamController.broadcast();

  Stream<Client> get clientStream => _clientStream.stream;

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
    await Matrix.of(context).client.getRoomById(spaceId)!.postLoad();
    if (mounted) {
      context.go('/spaces/$spaceId');
    }
  }

  // Needs to match GroupsSpacesEntry for 'separate group' checking.
  List<Room> get spaces =>
      Matrix.of(context).client.rooms.where((r) => r.isSpace).toList();

  String? get activeRoomId => widget.activeRoomId;

  bool get isSelectMode => selectModeNotifier.value == SelectMode.select;

  @override
  void initState() {
    if (kIsWeb) {
      BrowserContextMenu.disableContextMenu();
    }
    initReceiveSharingIntent();

    scrollController.addListener(_onScroll);
    _waitForFirstSync();
    _hackyWebRTCFixForWeb();
    CallKeepManager().initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        searchServer = await Store().getItem(_serverStoreNamespace);
        Matrix.of(context).backgroundPush?.setupPush();
      }
    });

    _checkTorBrowser();
    super.initState();
  }

  @override
  void dispose() {
    intentDataStreamSubscription?.cancel();
    intentFileStreamSubscription?.cancel();
    intentUriStreamSubscription?.cancel();
    scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void toggleSelection(String roomId) {
    final conversation = conversationSelectionNotifier.value.firstWhereOrNull(
      (conversation) => conversation.roomId == roomId,
    );

    final Set<ConversationSelectionPresentation> temp =
        conversationSelectionNotifier.value.toSet();

    if (conversation != null) {
      temp.remove(conversation);
    } else {
      temp.add(
        ConversationSelectionPresentation(
          roomId: roomId,
          selectionType: SelectionType.selected,
        ),
      );
    }

    conversationSelectionNotifier.value = temp.toList();
  }

  void toggleSelectMode() {
    selectModeNotifier.value =
        isSelectMode ? SelectMode.normal : SelectMode.select;
    clearSelection();
  }

  void clearSelection() {
    conversationSelectionNotifier.value = [];
  }

  void toggleUnread() async {
    await showFutureLoadingDialog(
      context: context,
      future: () async {
        final markUnread = anySelectedRoomNotMarkedUnread;
        final client = Matrix.of(context).client;
        for (final conversation in conversationSelectionNotifier.value) {
          final room = client.getRoomById(conversation.roomId)!;
          if (room.markedUnread == markUnread) continue;
          await client.getRoomById(conversation.roomId)!.markUnread(markUnread);
        }
      },
    );
    toggleSelectMode();
  }

  void toggleFavouriteRoom() async {
    await showFutureLoadingDialog(
      context: context,
      future: () async {
        final makeFavorite = anySelectedRoomNotFavorite;
        final client = Matrix.of(context).client;
        for (final conversation in conversationSelectionNotifier.value) {
          final room = client.getRoomById(conversation.roomId)!;
          if (room.isFavourite == makeFavorite) continue;
          await client
              .getRoomById(conversation.roomId)!
              .setFavourite(makeFavorite);
        }
      },
    );
    toggleSelectMode();
  }

  void toggleMuted() async {
    await showFutureLoadingDialog(
      context: context,
      future: () async {
        final newState = anySelectedRoomNotMuted
            ? PushRuleState.mentionsOnly
            : PushRuleState.notify;
        final client = Matrix.of(context).client;
        for (final conversation in conversationSelectionNotifier.value) {
          final room = client.getRoomById(conversation.roomId)!;
          if (room.pushRuleState == newState) continue;
          await client
              .getRoomById(conversation.roomId)!
              .setPushRuleState(newState);
        }
      },
    );
    toggleSelectMode();
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
    await showFutureLoadingDialog(
      context: context,
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
    await showFutureLoadingDialog(
      context: context,
      future: () => Matrix.of(context).client.setPresence(
            Matrix.of(context).client.userID!,
            PresenceType.online,
            statusMsg: input.single,
          ),
    );
  }

  Future<void> _archiveSelectedRooms() async {
    final client = Matrix.of(context).client;
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
    final result = await showFutureLoadingDialog(
      context: context,
      future: () async {
        final space = Matrix.of(context).client.getRoomById(selectedSpace)!;
        if (space.canSendDefaultStates) {
          for (final conversation in conversationSelectionNotifier.value) {
            await space.setSpaceChild(conversation.roomId);
          }
        }
      },
    );
    if (result.error == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.of(context)!.chatHasBeenAddedToThisSpace),
        ),
      );
    }

    conversationSelectionNotifier.value.clear();
  }

  bool get anySelectedRoomNotMarkedUnread =>
      conversationSelectionNotifier.value.any(
        (conversation) => !Matrix.of(context)
            .client
            .getRoomById(conversation.roomId)!
            .markedUnread,
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

  bool waitForFirstSync = false;

  Future<void> _waitForFirstSync() async {
    final client = Matrix.of(context).client;
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
            client.isUnknownSession && !mounted) {
          final recoveryWords = await _getRecoveryWords();
          if (recoveryWords != null) {
            await TomBootstrapDialog(
              client: client,
              recoveryWords: recoveryWords,
            ).show(context);
          } else {
            Logs().d(
              'ChatListController::_waitForFirstSync(): no recovery existed then call bootstrap',
            );
            await BootstrapDialog(client: client).show(context);
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
        ).show(context);
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
          .any((client) => client == Matrix.of(context).client)) {
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
        await showFutureLoadingDialog(
          context: context,
          future: () => client.setAccountBundle(bundle.single),
        );
        break;
      case EditBundleAction.removeFromBundle:
        await showFutureLoadingDialog(
          context: context,
          future: () => client.removeFromAccountBundle(activeBundle!),
        );
    }
  }

  bool get displayBundles =>
      Matrix.of(context).hasComplexBundles &&
      Matrix.of(context).accountBundles.keys.length > 1;

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

  void _onTapBottomNavigation(
    ChatListBottomNavigatorBar chatListBottomNavigatorBar,
  ) async {
    switch (chatListBottomNavigatorBar) {
      case ChatListBottomNavigatorBar.read:
        return toggleUnread();
      case ChatListBottomNavigatorBar.mute:
        return toggleMuted();
      case ChatListBottomNavigatorBar.pin:
        return toggleFavouriteRoom();
      case ChatListBottomNavigatorBar.more:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChatListView(
      controller: this,
      bottomNavigationBar: widget.bottomNavigationBar,
      onOpenSearchPage: widget.onOpenSearchPage,
      onTapBottomNavigation: _onTapBottomNavigation,
    );
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
}

enum EditBundleAction { addToBundle, removeFromBundle }
