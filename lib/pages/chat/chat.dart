import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/room/report_content_state.dart';
import 'package:fluffychat/domain/model/chat/message_report_reason.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/domain/model/file_info/file_info.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/domain/usecase/reactions/get_recent_reactions_interactor.dart';
import 'package:fluffychat/domain/usecase/reactions/store_recent_reactions_interactor.dart';
import 'package:fluffychat/domain/usecase/room/chat_get_pinned_events_interactor.dart';
import 'package:fluffychat/domain/usecase/room/report_content_interactor.dart';
import 'package:fluffychat/pages/chat/chat_actions.dart';
import 'package:fluffychat/pages/chat/chat_context_menu_actions.dart';
import 'package:fluffychat/pages/chat/chat_horizontal_action_menu.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_events_controller.dart';
import 'package:fluffychat/pages/chat/chat_report_message_additional_reason_dialog.dart';
import 'package:fluffychat/pages/chat/chat_view.dart';
import 'package:fluffychat/pages/chat/context_item_chat_action.dart';
import 'package:fluffychat/pages/chat/dialog_reject_invite_widget.dart';
import 'package:fluffychat/pages/chat/events/message_content_mixin.dart';
import 'package:fluffychat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:fluffychat/presentation/enum/chat/right_column_type_enum.dart';
import 'package:fluffychat/presentation/enum/chat/send_media_with_caption_status_enum.dart';
import 'package:fluffychat/presentation/extensions/client_extension.dart';
import 'package:fluffychat/presentation/extensions/event_update_extension.dart';
import 'package:fluffychat/presentation/extensions/send_file_extension.dart';
import 'package:fluffychat/presentation/extensions/send_file_web_extension.dart';
import 'package:fluffychat/presentation/mixins/audio_mixin.dart';
import 'package:fluffychat/presentation/mixins/auto_mark_as_read_mixin.dart';
import 'package:fluffychat/presentation/mixins/common_media_picker_mixin.dart';
import 'package:fluffychat/presentation/mixins/delete_event_mixin.dart';
import 'package:fluffychat/presentation/mixins/go_to_direct_chat_mixin.dart';
import 'package:fluffychat/presentation/mixins/handle_clipboard_action_mixin.dart';
import 'package:fluffychat/presentation/mixins/leave_chat_mixin.dart';
import 'package:fluffychat/presentation/mixins/media_picker_mixin.dart';
import 'package:fluffychat/presentation/mixins/paste_image_mixin.dart';
import 'package:fluffychat/presentation/mixins/save_file_to_twake_downloads_folder_mixin.dart';
import 'package:fluffychat/presentation/mixins/save_media_to_gallery_android_mixin.dart';
import 'package:fluffychat/presentation/mixins/send_files_mixin.dart';
import 'package:fluffychat/presentation/mixins/send_files_with_caption_web_mixin.dart';
import 'package:fluffychat/presentation/mixins/unblock_user_mixin.dart';
import 'package:fluffychat/presentation/model/chat/view_event_list_ui_state.dart';
import 'package:fluffychat/presentation/model/forward/forward_argument.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/account_bundles.dart';
import 'package:fluffychat/utils/adaptive_bottom_sheet.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/extension/basic_event_extension.dart';
import 'package:fluffychat/utils/extension/event_status_custom_extension.dart';
import 'package:fluffychat/utils/extension/global_key_extension.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/utils/manager/upload_manager/upload_manager.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/filtered_timeline_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/network_connection_service.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/utils/room_status_extension.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action_item_widget.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/mixins/drag_drog_file_mixin.dart';
import 'package:fluffychat/widgets/mixins/popup_context_menu_action_mixin.dart';
import 'package:fluffychat/widgets/mixins/popup_menu_widget_mixin.dart';
import 'package:fluffychat/widgets/mixins/popup_menu_widget_style.dart';
import 'package:fluffychat/widgets/mixins/twake_context_menu_mixin.dart';
import 'package:fluffychat/widgets/mixins/twake_context_menu_style.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart' as emoji_mart;
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linagora_design_flutter/dialog/options_dialog.dart';
import 'package:linagora_design_flutter/images_picker/asset_counter.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart'
    hide ImagePicker;
import 'package:linagora_design_flutter/reaction/reaction_picker.dart';
import 'package:matrix/matrix.dart' hide Contact;
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;

import 'events/audio_message/audio_player_widget.dart';
import 'send_file_dialog/send_file_dialog.dart';
import 'sticker_picker_dialog.dart';

typedef OnJumpToMessage = void Function(String eventId);

class Chat extends StatefulWidget {
  final String roomId;
  final List<MatrixFile?>? shareFiles;
  final String? roomName;
  final void Function(RightColumnType)? onChangeRightColumnType;
  final Stream<String>? jumpToEventStream;

  const Chat({
    super.key,
    required this.roomId,
    this.shareFiles,
    this.roomName,
    this.onChangeRightColumnType,
    this.jumpToEventStream,
  });

  @override
  ChatController createState() => ChatController();
}

class ChatController extends State<Chat>
    with
        CommonMediaPickerMixin,
        MediaPickerMixin,
        SendFilesWithCaptionWebMixin,
        SendFilesMixin,
        PopupContextMenuActionMixin,
        PopupMenuWidgetMixin,
        DragDrogFileMixin,
        GoToDraftChatMixin,
        PasteImageMixin,
        HandleClipboardActionMixin,
        TwakeContextMenuMixin,
        MessageContentMixin,
        SaveFileToTwakeAndroidDownloadsFolderMixin,
        SaveMediaToGalleryAndroidMixin,
        LeaveChatMixin,
        DeleteEventMixin,
        UnblockUserMixin,
        AudioMixin,
        AutoMarkAsReadMixin {
  final NetworkConnectionService networkConnectionService =
      getIt.get<NetworkConnectionService>();

  static const double _isPortionAvailableToScroll = 64;

  static const Duration _delayHideStickyTimestampHeader = Duration(seconds: 2);

  static const int _defaultEventCountDisplay = 30;

  static const double defaultMaxWidthReactionPicker = 326;

  static const double defaultMaxHeightReactionPicker = 360;

  final GlobalKey stickyTimestampKey =
      GlobalKey(debugLabel: 'stickyTimestampKey');

  final responsive = getIt.get<ResponsiveUtils>();

  final getPinnedMessageInteractor = getIt.get<ChatGetPinnedEventsInteractor>();

  final pinnedEventsController = getIt.get<PinnedEventsController>();

  final getRecentReactionsInteractor =
      getIt.get<GetRecentReactionsInteractor>();

  final storeRecentReactionsInteractor =
      getIt.get<StoreRecentReactionsInteractor>();

  final ValueKey chatComposerTypeAheadKey =
      const ValueKey('chatComposerTypeAheadKey');

  final ValueKey _chatMediaPickerTypeAheadKey =
      const ValueKey('chatMediaPickerTypeAheadKey');

  StreamSubscription? onUpdateEventStreamSubcription;

  StreamSubscription? ignoredUsersStreamSub;

  @override
  Room? room;

  Client? sendingClient;

  @override
  Timeline? timeline;

  MatrixState? matrix;

  Timer? _timestampTimer;

  String _markerReadLocation = '';

  String? unreadReceivedMessageLocation;

  List<MatrixFile?>? get shareFiles => widget.shareFiles;

  String? get roomName => widget.roomName;

  String? get roomId => widget.roomId;

  User? get user =>
      room?.unsafeGetUserFromMemoryOrFallback(room?.directChatMatrixID ?? '');

  final composerDebouncer =
      Debouncer<String>(const Duration(milliseconds: 100), initialValue: '');

  bool get hasNoMessageEvents {
    if (timeline == null) return true;

    final events = timeline!.events;
    final visibleEvents = events.where((event) => event.isVisibleInGui);
    final validEventType = [
      EventTypes.Message,
      EventTypes.Sticker,
      EventTypes.Encrypted,
      EventTypes.CallInvite,
    ];
    final validEvents = visibleEvents.where((event) {
      final currentMembership = event.content.tryGet<String>('membership');
      final prevMembership = event.prevContent?.tryGet<String>('membership');
      final isAcceptInviteEvent = event.type == EventTypes.RoomMember &&
          currentMembership == 'join' &&
          prevMembership == 'invite';
      return validEventType.contains(event.type) || isAcceptInviteEvent;
    });
    return validEvents.isEmpty;
  }

  bool get isSupportChat {
    return roomId == Matrix.of(context).supportChatRoomId;
  }

  bool get isEmptySupportChat {
    final supportChatRoomId = Matrix.of(context).supportChatRoomId;
    if (supportChatRoomId == null) return false;

    if (timeline == null) return true;

    final events = timeline!.events;
    final visibleEvents = events.where((event) => event.isVisibleInGui);
    final validEventType = [
      EventTypes.Message,
      EventTypes.Sticker,
      EventTypes.Encrypted,
      EventTypes.CallInvite,
    ];
    final validEvents = visibleEvents.where((event) {
      return validEventType.contains(event.type);
    });
    return validEvents.isEmpty && isSupportChat;
  }

  final AutoScrollController scrollController = AutoScrollController();

  // Constant scroll speed in pixels per second for smooth, predictable scrolling
  static const double _scrollSpeed = 2000.0;

  final KeyboardVisibilityController keyboardVisibilityController =
      KeyboardVisibilityController();

  final ValueNotifier<String?> focusHover = ValueNotifier(null);

  final ValueNotifier<bool> openingPopupMenu = ValueNotifier(false);

  final ValueNotifier<bool> showScrollDownButtonNotifier = ValueNotifier(false);

  final ValueNotifier<bool> showEmojiPickerNotifier = ValueNotifier(false);

  final ValueNotifier<bool> showEmojiPickerComposerNotifier =
      ValueNotifier(false);

  final ValueNotifier<DateTime?> stickyTimestampNotifier = ValueNotifier(null);

  final ValueNotifier<bool> showFullEmojiPickerOnWebNotifier =
      ValueNotifier(false);

  final ValueNotifier<ViewEventListUIState> openingChatViewStateNotifier =
      ValueNotifier(ViewEventListInitial());

  final ValueNotifier<bool> isBlockedUserNotifier = ValueNotifier(false);

  final FocusSuggestionController _focusSuggestionController =
      FocusSuggestionController();

  final AutoScrollController pinnedMessageScrollController =
      AutoScrollController();

  final TextEditingController _captionsController = TextEditingController();

  FocusNode inputFocus = FocusNode();

  FocusNode keyboardFocus = FocusNode();

  @override
  FocusNode chatFocusNode = FocusNode();

  final FocusNode rawKeyboardListenerFocusNode = FocusNode();

  final FocusNode searchEmojiFocusNode = FocusNode();

  Timer? typingCoolDown;
  Timer? typingTimeout;
  bool currentlyTyping = false;

  StreamSubscription<EventId>? _jumpToEventIdSubscription;

  StreamSubscription<String>? _jumpToEventFromSearchSubscription;

  bool get canSaveSelectedEvent =>
      selectedEvents.length == 1 &&
      {
        MessageTypes.Video,
        MessageTypes.Image,
        MessageTypes.Sticker,
        MessageTypes.Audio,
        MessageTypes.File,
      }.contains(selectedEvents.single.messageType);

  final showAddContactBanner = ValueNotifier(true);

  User? contactToAdd(Either<Failure, Success> state) {
    final isDirectChat = room?.isDirectChat == true;
    if (!isDirectChat) return null;

    final List<Contact> contacts = state.fold(
      (failure) => [],
      (success) => success is GetContactsSuccess ? success.contacts : [],
    );
    return room?.getParticipants().firstWhereOrNull(
          (user) =>
              user.id != client.userID &&
              contacts.none(
                (contact) => contact.inTomAddressBook(user.id),
              ),
        );
  }

  List<Event> selectedEvents = [];

  final Set<String> unfolded = {};

  final replyEventNotifier = ValueNotifier<Event?>(null);

  final editEventNotifier = ValueNotifier<Event?>(null);

  bool get selectMode => selectedEvents.isNotEmpty;

  Client get client => matrix?.client ?? Matrix.read(context).client;

  final int _loadHistoryCount = 100;

  final inputText = ValueNotifier('');

  String pendingText = '';

  DateTime _currentDateTimeEvent = DateTime.now();

  ChatScrollState _currentChatScrollState = ChatScrollState.endScroll;

  AutoScrollController suggestionScrollController = AutoScrollController();

  SuggestionsController<Map<String, String?>> suggestionsController =
      SuggestionsController();

  ValueNotifier<CachedPresence?> cachedPresenceNotifier = ValueNotifier(null);

  StreamController<CachedPresence> cachedPresenceStreamController =
      StreamController.broadcast();
  StreamSubscription<CachedPresence>? cachedPresenceStreamSubscription;

  Future<void> initCachedPresence() async {
    cachedPresenceNotifier.value = room?.directChatPresence;
    if (room?.directChatMatrixID != null) {
      cachedPresenceStreamSubscription =
          Matrix.of(context).onLatestPresenceChanged.stream.listen((event) {
        if (event.userid == room!.directChatMatrixID) {
          Logs().v(
            'onlatestPresenceChanged: ${event.presence}, ${event.lastActiveTimestamp}',
          );
          cachedPresenceStreamController.add(event);
        }
      });
      try {
        final getPresenceResponse = await client.getPresence(
          room!.directChatMatrixID!,
        );

        cachedPresenceNotifier.value = CachedPresence.fromPresenceResponse(
          getPresenceResponse,
          room!.directChatMatrixID!,
        );
      } catch (e) {
        Logs().e('Failed to get presence', e);
        cachedPresenceNotifier.value =
            CachedPresence.neverSeen(room!.directChatMatrixID!);
      }
    }
  }

  Future<void> _requestParticipants() async {
    if (room == null) return;
    try {
      await room!.requestParticipants(
        Membership.values
            .whereNot((membership) => membership == Membership.leave)
            .toList(),
        false,
        true,
      );
    } catch (e) {
      Logs()
          .e('Chat::_requestParticipants(): Failed to request participants', e);
    }
  }

  bool isUnpinEvent(Event event) =>
      room?.pinnedEventIds
          .firstWhereOrNull((eventId) => eventId == event.eventId) !=
      null;

  void updateInputTextNotifier() {
    if (audioRecordStateNotifier.value == AudioRecordState.recording ||
        audioRecordStateNotifier.value == AudioRecordState.paused) {
      return;
    }
    inputText.value = sendController.text;
  }

  bool isSelected(Event event) => selectedEvents.any(
        (e) => e.eventId == event.eventId,
      );

  String? _findUnreadReceivedMessageLocation() {
    if (timeline == null) return null;
    final events = timeline!.events;
    if (_markerReadLocation != '' && _markerReadLocation.isNotEmpty) {
      final lastIndexReadEvent = events.indexWhere(
        (event) => event.eventId == _markerReadLocation,
      );
      if (lastIndexReadEvent > 0) {
        final afterFullyRead = events.getRange(0, lastIndexReadEvent);
        final unreadEvents = afterFullyRead
            .where((event) => event.senderId != client.userID)
            .toList();
        if (unreadEvents.isEmpty) return null;
        Logs().d(
          "Chat::getFirstUnreadEvent(): Last unread event ${unreadEvents.last}",
        );
        return unreadEvents.last.eventId;
      }
    } else {
      return null;
    }
    return null;
  }

  void recreateChat() async {
    final room = this.room;
    final userId = room?.directChatMatrixID;
    if (room == null || userId == null) {
      throw Exception(
        'Try to recreate a room with is not a DM room. This should not be possible from the UI!',
      );
    }
    final success = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        final client = room.client;
        final waitForSync = client.onSync.stream
            .firstWhere((s) => s.rooms?.leave?.containsKey(room.id) ?? false);
        await room.leave();
        await waitForSync;
        return await client.startDirectChat(userId, enableEncryption: true);
      },
    );
    final roomId = success.result;
    if (roomId == null) return;
    context.go('/rooms/$roomId');
  }

  Future<void> requestHistory({
    int? historyCount,
    StateFilter? filter,
  }) async {
    if (!timeline!.canRequestHistory) return;
    Logs().v('Chat::requestHistory(): Requesting history...');
    try {
      return timeline!.requestHistory(
        historyCount: historyCount ?? _loadHistoryCount,
        filter: filter,
      );
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (err).toLocalizedString(context),
          ),
        ),
      );
      rethrow;
    }
  }

  void _updateScrollController() async {
    if (!mounted) {
      return;
    }
    if (!scrollController.hasClients) return;
    if (timeline?.allowNewEvent == false) {
      showScrollDownButtonNotifier.value = true;
    } else {
      showScrollDownButtonNotifier.value = scrollController.position.pixels !=
          scrollController.position.maxScrollExtent;
    }
    if (scrollController.position.pixels ==
            scrollController.position.maxScrollExtent ||
        scrollController.position.pixels == _isPortionAvailableToScroll) {
      requestFuture();
    }

    _handleRequestHistory();
  }

  void _handleRequestHistory() {
    if (scrollController.position.pixels ==
            scrollController.position.minScrollExtent ||
        scrollController.position.pixels - _isPortionAvailableToScroll ==
            scrollController.position.minScrollExtent) {
      if (timeline?.isRequestingHistory == true) return;
      if (timeline?.canRequestHistory == true) {
        requestHistory();
      }
    }
  }

  void _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draft = prefs.getString('draft_$roomId');
    if (draft != null && draft.isNotEmpty) {
      sendController.text = draft;
      inputText.value = draft;
    }
  }

  void _keyboardListener(bool isKeyboardVisible) {}

  void handleDragDone(DropDoneDetails details) async {
    final matrixFiles = await onDragDone(details);
    final pendingText = sendController.text;
    sendController.clear();
    sendFileOnWebAction(
      context,
      room: room,
      pendingText: pendingText,
      matrixFilesList: matrixFiles,
      onSendFileCallback: (result) async {
        await handleSendMediaCallback(
          result: result.status,
          pendingText: pendingText,
        );
      },
    );
  }

  void _handleReceivedShareFiles() {
    if (shareFiles != null && room != null) {
      final filesIsNotNull = shareFiles!.whereNotNull();
      final uploadManger = getIt.get<UploadManager>();
      uploadManger.uploadFileMobile(
        room: room!,
        fileInfos: filesIsNotNull
            .map((file) => FileInfo.fromMatrixFile(file))
            .toList(),
      );
    }
  }

  void _initUnreadLocation(String fullyRead) {
    _markerReadLocation = fullyRead;
    unreadReceivedMessageLocation = _findUnreadReceivedMessageLocation();
    scrollToEventId(fullyRead, highlight: false);
  }

  void _tryLoadTimeline() async {
    _updateOpeningChatViewStateNotifier(ViewEventListLoading());
    loadTimelineFuture = _getTimeline(
      onJumpToMessage: (event) {
        scrollToEventId(event);
      },
    );
    try {
      await loadTimelineFuture;
      await _tryRequestHistory();
      final fullyRead = room?.fullyRead;
      if (fullyRead == null || fullyRead.isEmpty || fullyRead == '') {
        return;
      }
      if (room?.hasNewMessages == true) {
        _initUnreadLocation(fullyRead);
      }
      if (!mounted) return;
    } catch (e, s) {
      Logs().e('Failed to load timeline', e, s);
      rethrow;
    }
  }

  void updateView() {
    if (!mounted) return;
    setState(() {});
  }

  void onBackPress() {
    context.pop();
  }

  Future<void>? _setReadMarkerFuture;
  String? _pendingReadMarkerEventId;

  @override
  Future<void> setReadMarker({String? eventId}) async {
    if (!mounted || room == null) return;

    // Store the latest request
    _pendingReadMarkerEventId = eventId;

    // If already processing, just coalesce; the worker will pick it up.
    if (_setReadMarkerFuture != null) return;

    try {
      _setReadMarkerFuture = _processReadMarker();
      await _setReadMarkerFuture;
    } finally {
      _setReadMarkerFuture = null;
    }
  }

  Future<void> _processReadMarker() async {
    while (true) {
      if (!mounted) return;
      final timeline = this.timeline;
      if (timeline == null || timeline.events.isEmpty) return;

      final currentEventId = _pendingReadMarkerEventId;
      _pendingReadMarkerEventId = null;

      Logs().d('Set read marker...', currentEventId);

      try {
        await timeline.setReadMarker(eventId: currentEventId);
      } catch (e, s) {
        Logs().e('Failed to set read marker', e, s);
        return;
      }

      if (!mounted) return;
      if (currentEventId == null ||
          currentEventId == timeline.room.lastEvent?.eventId) {
        Matrix.of(context).backgroundPush?.cancelNotification(roomId!);
      }

      // If no new request arrived while we awaited, we're done.
      if (_pendingReadMarkerEventId == null) return;
    }
  }

  final FocusSuggestionController focusSuggestionController =
      FocusSuggestionController();

  void setSendingClient(Client? c) {
    // first cancle typing with the old sending client
    if (currentlyTyping) {
      // no need to have the setting typing to false be blocking
      typingCoolDown?.cancel();
      typingCoolDown = null;
      room!.setTyping(false);
      currentlyTyping = false;
    }
    // then set the new sending client
    setState(() => sendingClient = c);
  }

  Future<void> send() async {
    scrollDown();
    showEmojiPickerNotifier.value = false;

    if (sendController.text.trim().isEmpty) return;
    _storeInputTimeoutTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('draft_$roomId');
    var parseCommands = true;

    final commandMatch = RegExp(r'^/(\w+)').firstMatch(sendController.text);
    if (commandMatch != null &&
        !room!.client.commands.keys.contains(commandMatch[1]!.toLowerCase())) {
      final l10n = L10n.of(context)!;
      final dialogResult = await showOkCancelAlertDialog(
        context: context,
        useRootNavigator: false,
        title: l10n.commandInvalid,
        message: l10n.commandMissing(commandMatch[0]!),
        okLabel: l10n.sendAsText,
        cancelLabel: l10n.cancel,
      );
      if (dialogResult == OkCancelResult.cancel) return;
      parseCommands = false;
    }

    // ignore: unawaited_futures
    room!.sendTextEvent(
      sendController.text.trim(),
      inReplyTo: replyEventNotifier.value,
      editEventId: editEventNotifier.value?.eventId,
      parseCommands: parseCommands,
    );
    sendController.value = TextEditingValue(
      text: pendingText,
      selection: const TextSelection.collapsed(offset: 0),
    );
    inputText.value = pendingText;
    _updateReplyEvent();
    setState(() {
      editEventNotifier.value = null;
      pendingText = '';
    });
  }

  void openVideoCameraAction() async {
    // Make sure the textfield is unfocused before opening the camera
    FocusScope.of(context).requestFocus(FocusNode());
    final file = await ImagePicker().pickVideo(source: ImageSource.camera);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    await showDialog(
      context: context,
      useRootNavigator: false,
      builder: (c) => SendFileDialog(
        files: [
          MatrixVideoFile(
            bytes: bytes,
            name: file.path,
          ),
        ],
        room: room!,
      ),
    );
  }

  void sendStickerAction() async {
    final sticker = await showAdaptiveBottomSheet<ImagePackImageContent>(
      context: context,
      builder: (c) => StickerPickerDialog(room: room!),
    );
    if (sticker == null) return;
    final eventContent = <String, dynamic>{
      'body': sticker.body,
      if (sticker.info != null) 'info': sticker.info,
      'url': sticker.url.toString(),
    };
    // send the sticker
    await room!.sendEvent(
      eventContent,
      type: EventTypes.Sticker,
    );
  }

  Future<void> sendVoiceMessageWeb() async {
    final duration = Duration(seconds: recordDurationWebNotifier.value);
    final path = await stopRecordWeb();
    final file = await recordToFileOnWeb(
      blobUrl: path,
    );

    if (file == null) {
      TwakeSnackBar.show(context, L10n.of(context)!.audioMessageFailedToSend);
      return;
    }

    final matrixFile = await createMatrixAudioFileFromWebFile(
      file: file,
      duration: duration,
    );

    if (matrixFile == null) {
      TwakeSnackBar.show(context, L10n.of(context)!.audioMessageFailedToSend);
      return;
    }

    final fileInfo = FileInfo(
      matrixFile.name,
      bytes: matrixFile.bytes,
    );

    final txid = client.generateUniqueTransactionId();

    room?.sendingFilePlaceholders[txid] = matrixFile;

    final extraContent = {
      'info': {
        ...matrixFile.info,
        'duration': duration.inMilliseconds,
      },
      'org.matrix.msc3245.voice': {},
      'org.matrix.msc1767.audio': {
        'duration': duration.inMilliseconds,
        'waveform': convertWaveformWeb(),
      },
    };

    final fakeImageEvent = await room?.sendFakeFileInfoEvent(
      fileInfo,
      txid: txid,
      messageType: MessageTypes.Audio,
      inReplyTo: replyEventNotifier.value,
      extraContent: extraContent,
    );

    if (fakeImageEvent == null) {
      TwakeSnackBar.show(context, L10n.of(context)!.audioMessageFailedToSend);
      Logs().e('Failed to create fake image event for voice message');
      return;
    }

    await room!
        .sendFileOnWebEvent(
      matrixFile,
      txid: txid,
      fakeImageEvent: fakeImageEvent,
      inReplyTo: replyEventNotifier.value,
      extraContent: extraContent,
    )
        .catchError((e) {
      TwakeSnackBar.show(context, L10n.of(context)!.audioMessageFailedToSend);
      Logs().e('Failed to send voice message', e);
      return null;
    });
    _updateReplyEvent();
  }

  Future<void> sendVoiceMessageAction({
    required TwakeAudioFile audioFile,
    required String path,
    required Duration time,
    required List<int> waveform,
  }) async {
    final fileInfo = FileInfo(
      audioFile.name,
      filePath: path,
    );

    final txid = client.generateUniqueTransactionId();

    room?.sendingFilePlaceholders[txid] = audioFile;

    final extraContent = {
      'info': {
        ...audioFile.info,
        'duration': time.inMilliseconds,
      },
      'org.matrix.msc3245.voice': {},
      'org.matrix.msc1767.audio': {
        'duration': time.inMilliseconds,
        'waveform': waveform,
      },
    };

    final fakeImageEvent = await room?.sendFakeFileInfoEvent(
      fileInfo,
      txid: txid,
      messageType: MessageTypes.Audio,
      inReplyTo: replyEventNotifier.value,
      extraContent: extraContent,
    );

    if (fakeImageEvent == null) {
      TwakeSnackBar.show(context, L10n.of(context)!.audioMessageFailedToSend);
      Logs().e('Failed to create fake event for voice message');
      return;
    }

    await room!
        .sendFileEventMobile(
      fileInfo,
      txid: txid,
      msgType: MessageTypes.Audio,
      fakeImageEvent: fakeImageEvent,
      inReplyTo: replyEventNotifier.value,
      extraContent: extraContent,
    )
        .then((_) {
      room?.sendingFilePlaceholders.remove(txid);
    }).catchError((e) {
      TwakeSnackBar.show(context, L10n.of(context)!.audioMessageFailedToSend);
      Logs().e('Failed to send voice message', e);
      return null;
    });
    _updateReplyEvent();
  }

  void onEmojiAction(TapDownDetails tapDownDetails) {
    if (PlatformInfos.isMobile) return;

    showEmojiPickerComposerNotifier.value = true;
  }

  void copySingleEventAction() async {
    if (selectedEvents.length == 1) {
      await selectedEvents.first.copy(context, timeline!);
    }
  }

  void copyEventsAction(Event event) async {
    await event.copyTextEvent(context, timeline!);

    showEmojiPickerNotifier.value = false;
    _clearSelectEvent();
  }

  void reportEventAction(Event event) async {
    if (audioRecordStateNotifier.value != AudioRecordState.initial) {
      preventActionWhileRecordingMobile(context: context);
      return;
    }
    final l10n = L10n.of(context)!;
    final options = MessageReportReason.values.map((reportReason) {
      return LinagoraDialogOption(
        name: reportReason.getReason(l10n),
        value: reportReason,
        trailingIcon: reportReason.getTrailingIcon(),
      );
    }).toList();
    final selectedOption =
        await showDialog<LinagoraDialogOption<MessageReportReason>>(
      context: context,
      builder: (context) {
        return OptionsDialog(
          title: l10n.report,
          description: l10n.reportDesc,
          isBottomSheet: MediaQuery.sizeOf(context).width < 600,
          availableOptions: options,
          onSelected: (selected) => Navigator.pop(context, selected),
        );
      },
    );
    if (selectedOption == null) return;
    String additionalReason = '';
    if (selectedOption.value == MessageReportReason.other) {
      bool isBacked = false;
      final comment = await showDialog<String>(
        context: context,
        builder: (context) {
          return ChatReportMessageAdditionalReasonDialog(
            l10n: l10n,
            isMobile: responsive.isMobile(context),
            onCommentReport: (comment) => Navigator.pop(context, comment),
            onBack: () {
              isBacked = true;
              Navigator.pop(context);
            },
          );
        },
      );
      if (isBacked) {
        reportEventAction(event);
        return;
      }
      if (comment == null) return;
      additionalReason = comment;
    }
    final result = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        final state = await getIt
            .get<ReportContentInteractor>()
            .execute(
              client: client,
              roomId: event.roomId!,
              eventId: event.eventId,
              reason: selectedOption.value == MessageReportReason.other
                  ? '${selectedOption.value.getReason(l10n)}: $additionalReason'
                  : selectedOption.value.getReason(l10n),
              score: selectedOption.value.score,
            )
            .last;
        return state.fold(
          (failure) {
            if (failure is ReportContentFailure) {
              throw failure.exception;
            }
            return failure;
          },
          (success) => success,
        );
      },
    );
    showEmojiPickerNotifier.value = false;
    _clearSelectEvent();
    if (result.error != null) {
      TwakeSnackBar.show(
        context,
        result.error.toLocalizedString(context),
      );
      return;
    }
    TwakeSnackBar.show(context, l10n.contentHasBeenReported);
  }

  void redactEventsAction() async {
    final confirmed = await showOkCancelAlertDialog(
          useRootNavigator: false,
          context: context,
          title: L10n.of(context)!.messageWillBeRemovedWarning,
          okLabel: L10n.of(context)!.remove,
          cancelLabel: L10n.of(context)!.cancel,
        ) ==
        OkCancelResult.ok;
    if (!confirmed) return;
    for (final event in selectedEvents) {
      await TwakeDialog.showFutureLoadingDialogFullScreen(
        future: () async {
          if (event.status.isSent) {
            if (event.canRedact) {
              await event.redactEvent();
            } else {
              final client = currentRoomBundle.firstWhere(
                (cl) => selectedEvents.first.senderId == cl!.userID,
                orElse: () => null,
              );
              if (client == null) {
                return;
              }
              final room = client.getRoomById(roomId!)!;
              await Event.fromJson(event.toJson(), room).redactEvent();
            }
          } else {
            await event.remove();
          }
        },
      );
    }
    showEmojiPickerNotifier.value = false;
    _clearSelectEvent();
  }

  List<Client?> get currentRoomBundle {
    final clients = matrix!.currentBundle!;
    clients.removeWhere((c) => c!.getRoomById(roomId!) == null);
    return clients;
  }

  bool get canRedactSelectedEvents {
    if (isArchived) return false;
    final clients = matrix!.currentBundle;
    for (final event in selectedEvents) {
      if (event.canRedact == false &&
          !(clients!.any((cl) => event.senderId == cl!.userID))) {
        return false;
      }
    }
    return true;
  }

  bool get canEditSelectedEvents {
    if (isArchived ||
        selectedEvents.length != 1 ||
        !selectedEvents.first.status.isSent) {
      return false;
    }
    return currentRoomBundle
        .any((cl) => selectedEvents.first.senderId == cl!.userID);
  }

  void forwardEventsAction({Event? event}) async {
    if (audioRecordStateNotifier.value != AudioRecordState.initial) {
      preventActionWhileRecordingMobile(context: context);
      return;
    }
    if (event != null && !event.status.isAvailable) {
      return;
    }
    if (selectedEvents.isEmpty && event != null) {
      Matrix.of(context).shareContent = event
          .getDisplayEventWithoutEditEvent(timeline!)
          .formatContentForwards();
      Logs().d(
        "forwardEventsAction():: shareContent: ${Matrix.of(context).shareContent}",
      );
    } else {
      Matrix.of(context).shareContentList = selectedEvents.map((msg) {
        final content = msg
            .getDisplayEventWithoutEditEvent(timeline!)
            .formatContentForwards();
        return content;
      }).toList();
      Logs().d(
        "forwardEventsAction():: shareContentList: ${Matrix.of(context).shareContentList}",
      );
    }
    _clearSelectEvent();
    context.push(
      '/rooms/forward',
      extra: ForwardArgument(
        fromRoomId: roomId ?? '',
      ),
    );
  }

  void sendAgainAction() {
    final event = selectedEvents.first;
    if (event.status.isError) {
      event.sendAgain();
    }
    final allEditEvents = event
        .aggregatedEvents(timeline!, RelationshipTypes.edit)
        .where((e) => e.status.isError);
    for (final e in allEditEvents) {
      e.sendAgain();
    }
    _clearSelectEvent();
  }

  void editAction({
    Event? editEvent,
  }) {
    if (audioRecordStateNotifier.value != AudioRecordState.initial) {
      preventActionWhileRecordingMobile(context: context);
      return;
    }
    if (replyEventNotifier.value != null) {
      cancelReplyEventAction();
    }
    final eventToEdit = editEvent ?? selectedEvents.first;

    if (!eventToEdit.status.isAvailable) {
      return;
    }
    pendingText = sendController.text;
    editEventNotifier.value = eventToEdit;
    sendController.text = eventToEdit.isMediaAndFilesWithCaption()
        ? eventToEdit.body
        : eventToEdit
            .getDisplayEventWithoutEditEvent(timeline!)
            .calcLocalizedBodyFallback(
              MatrixLocals(L10n.of(context)!),
              withSenderNamePrefix: false,
              hideReply: true,
            );

    _clearSelectEvent();
    _requestInputFocus();
  }

  void replyAction({
    Event? replyTo,
  }) {
    if (audioRecordStateNotifier.value != AudioRecordState.initial) {
      preventActionWhileRecordingMobile(context: context);
      return;
    }
    if (editEventNotifier.value != null) {
      cancelEditEventAction();
    }
    if (replyTo?.status.isAvailable == false) {
      return;
    }
    _updateReplyEvent(
      event: replyTo ?? selectedEvents.first,
    );
    _clearSelectEvent();
    _requestInputFocus();
  }

  Future<void> scrollToEventIdAndHighlight(String eventId) async {
    return await scrollToEventId(eventId, highlight: true);
  }

  Future<void>? loadTimelineFuture;

  void requestFuture() async {
    final timeline = this.timeline;
    if (timeline == null) return;
    if (!timeline.canRequestFuture) return;
    Logs().v('Chat::requestFuture(): Requesting future...');
    try {
      await timeline.requestFuture(historyCount: _loadHistoryCount);
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (err).toLocalizedString(context),
          ),
        ),
      );
      rethrow;
    }
  }

  Future<void> _getTimeline({
    String? eventContextId,
    OnJumpToMessage? onJumpToMessage,
  }) async {
    await Matrix.of(context).client.roomsLoading;
    await Matrix.of(context).client.accountDataLoading;
    if (eventContextId != null &&
        (!eventContextId.isValidMatrixId || eventContextId.sigil != '\$')) {
      eventContextId = null;
    }
    if (timeline != null) {
      timeline!.cancelSubscriptions();
    }
    try {
      timeline = await room?.getTimeline(
        onUpdate: updateView,
        eventContextId: eventContextId,
      );
    } catch (e, s) {
      Logs().w('Unable to load timeline on event ID $eventContextId', e, s);
      if (!mounted) return;
      timeline = await room?.getTimeline(onUpdate: updateView);
      if (!mounted) return;
    }
    timeline?.requestKeys(onlineKeyBackupOnly: false);
    if (room!.markedUnread) room?.markUnread(false);
    // when the scroll controller is attached we want to scroll to an event id, if specified
    // and update the scroll controller...which will trigger a request history, if the
    // "load more" button is visible on the screen
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      String? eventId;

      if (PlatformInfos.isMobile) {
        eventId = GoRouterState.of(context).uri.queryParameters['event'];
      } else {
        final currentLocation = html.window.location.href;

        eventId = Uri.tryParse(Uri.tryParse(currentLocation)?.fragment ?? '')
            ?.queryParameters['event'];
      }

      if (eventId != null) {
        onJumpToMessage?.call(eventId);
      }
    });

    return;
  }

  bool verifyEventIdInTimeline(Timeline? timeline, String? eventId) {
    if (eventId == null) return false;
    if (timeline == null) return false;
    if (timeline.events.isEmpty) return false;

    final foundEvent = timeline.events
        .where((e) => e.isVisibleInGui)
        .firstWhereOrNull((e) => e.eventId == eventId);

    return foundEvent != null;
  }

  void scrollDown() async {
    if (timeline == null) return;
    if (!timeline!.allowNewEvent) {
      setState(() {
        timeline = null;
        loadTimelineFuture = _getTimeline().onError(
          (e, s) {
            Logs().e('Chat::scrollDown(): Unable to load timeline', e, s);
          },
        );
      });
      await loadTimelineFuture;
    }
    if (scrollController.positions.isNotEmpty) {
      while (scrollController.position.pixels !=
          scrollController.position.maxScrollExtent) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    }
    _handleHideStickyTimestamp();
  }

  int getDisplayEventIndex(int eventIndex) {
    const addedHeadItemsInChat = 1;
    return eventIndex + addedHeadItemsInChat;
  }

  int _getEventIndex(String eventId) {
    if (timeline == null) return -1;
    final foundEvent =
        timeline!.events.firstWhereOrNull((event) => event.eventId == eventId);

    final eventIndex = foundEvent == null
        ? -1
        : timeline!.events.indexWhere(
            (event) => event.eventId == foundEvent.eventId,
          );

    return eventIndex;
  }

  Future<void> scrollToEventId(
    String eventId, {
    bool highlight = true,
    int maxAttempts = 3,
    int currentAttempt = 0,
  }) async {
    final eventIndex = _getEventIndex(eventId);
    if (eventIndex == -1) {
      if (currentAttempt >= maxAttempts) {
        Logs().e(
          'Chat::scrollToEventId(): Max attempts ($maxAttempts) reached for event $eventId',
        );
        return;
      }
      setState(() {
        timeline = null;
        loadTimelineFuture = _getTimeline(
          eventContextId: eventId,
        ).onError(
          (e, s) {
            Logs().e('Chat::scrollToEventId(): Unable to load timeline', e, s);
          },
        );
      });
      await loadTimelineFuture;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (verifyEventIdInTimeline(timeline, eventId)) {
          scrollToEventId(
            eventId,
            highlight: highlight,
            maxAttempts: maxAttempts,
            currentAttempt: currentAttempt + 1,
          );
        }
      });
      return;
    }
    await _scrollToMessageWithEventId(eventId);
    if (highlight) {
      await scrollController.highlight(
        getDisplayEventIndex(eventIndex),
      );
    }
    _updateScrollController();
  }

  /// Scrolls to a message with the given [eventId] and centers it in the viewport.
  ///
  /// This method handles two scenarios:
  /// 1. If the message is already rendered, it centers it immediately
  /// 2. If not rendered, it gradually scrolls towards it until found
  ///
  /// **Important**: Due to GlobalObjectKey behavior on mobile, we must create
  /// fresh key instances from `timeline.events[index].eventId` rather than
  /// reusing the passed [eventId] parameter to ensure reliable context lookups.
  Future<void> _scrollToMessageWithEventId(String eventId) async {
    if (timeline == null) return;

    final targetIndex =
        timeline!.events.indexWhere((event) => event.eventId == eventId);
    if (targetIndex == -1) return;

    // Check if target message is already rendered in viewport
    // Use event from timeline to ensure reliable GlobalObjectKey lookup
    final targetEventId = timeline!.events[targetIndex].eventId;
    final itemContext = GlobalObjectKey(targetEventId).currentContext;

    if (itemContext != null) {
      // Message is rendered - center it in viewport
      await _centerRenderedMessage(itemContext);
      return;
    }

    // Message not rendered - scroll towards it
    await _scrollTowardsMessage(eventId, targetIndex);
  }

  /// Centers an already-rendered message in the viewport.
  Future<void> _centerRenderedMessage(BuildContext itemContext) async {
    final itemBox = itemContext.findRenderObject() as RenderBox?;
    final scrollBox = scrollController.position.context.notificationContext
        ?.findRenderObject() as RenderBox?;
    if (itemBox == null || scrollBox == null) return;

    final itemPosition =
        itemBox.localToGlobal(Offset.zero, ancestor: scrollBox);
    final viewportHeight = scrollBox.size.height;
    final itemHeight = itemBox.size.height;

    // Calculate scroll adjustment to center the message
    final scrollAdjustment =
        itemPosition.dy - (viewportHeight / 2) + (itemHeight / 2);
    final targetOffset = scrollController.offset + scrollAdjustment;

    // Calculate duration based on distance and constant speed
    final distance = scrollAdjustment.abs();
    final duration = Duration(
      milliseconds: (distance / _scrollSpeed * 1000).toInt(),
    );

    await scrollController.animateTo(
      targetOffset,
      duration: duration,
      curve: Curves.linear,
    );
  }

  /// Gradually scrolls towards a message until it becomes rendered.
  ///
  /// Uses a continuous scroll animation with periodic checks, eliminating
  /// the pause-between-steps that occurs with iterative scrolling.
  ///
  /// This method will retry scrolling if the target isn't found on the first attempt.
  Future<void> _scrollTowardsMessage(
    String eventId,
    int targetIndex, {
    int retryCount = 0,
  }) async {
    const checkIntervalMs = 50;
    const maxRetries = 5;

    final eventsCount = timeline!.events.length;
    if (eventsCount == 0) return;

    // Find nearest rendered message to determine scroll direction
    final nearestRenderedIndex = _findVisibleEventIndex();
    if (nearestRenderedIndex == null) {
      // No rendered messages found - use AutoScrollController as fallback
      Logs().w(
        'Chat::_scrollTowardsMessage(): No rendered messages found, using AutoScrollController fallback',
      );
      await scrollController.scrollToIndex(
        getDisplayEventIndex(targetIndex),
        preferPosition: AutoScrollPosition.middle,
        duration: const Duration(milliseconds: 300),
      );
      return;
    }

    // Determine scroll direction and estimate distance
    final shouldScrollDown = targetIndex < nearestRenderedIndex;
    final messageDistance = (targetIndex - nearestRenderedIndex).abs();

    // Use a more accurate estimate: 180 pixels per message with 50% safety margin
    // Based on logs: 800px scrolled only 5 messages, so ~160px/message minimum
    final estimatedDistance = messageDistance * 180.0 * 1.5;

    // Calculate target offset for continuous scroll
    final currentOffset = scrollController.offset;
    final scrollDirection =
        shouldScrollDown ? estimatedDistance : -estimatedDistance;
    final estimatedTargetOffset = (currentOffset + scrollDirection).clamp(
      scrollController.position.minScrollExtent,
      scrollController.position.maxScrollExtent,
    );

    // Start continuous scroll animation
    final scrollDuration = Duration(
      milliseconds: (estimatedDistance / _scrollSpeed * 1000).toInt(),
    );

    // Start the animation (non-blocking)
    final animationFuture = scrollController.animateTo(
      estimatedTargetOffset,
      duration: scrollDuration,
      curve: Curves.linear,
    );

    // Periodically check if target is rendered while scrolling
    final stopwatch = Stopwatch()..start();
    bool reachedBoundary = false;

    while (stopwatch.elapsedMilliseconds < scrollDuration.inMilliseconds) {
      await Future.delayed(const Duration(milliseconds: checkIntervalMs));

      final isRendered = _isMessageRendered(targetIndex);
      final currentPos = scrollController.offset;

      if (isRendered) {
        // Found it! Stop the animation by jumping to current position
        scrollController.jumpTo(currentPos);
        stopwatch.stop();

        // Center the message
        await _scrollToMessageWithEventId(eventId);
        return;
      }

      // Check if we've reached scroll boundary
      if (currentPos == scrollController.position.minScrollExtent ||
          currentPos == scrollController.position.maxScrollExtent) {
        stopwatch.stop();
        reachedBoundary = true;
        break;
      }
    }

    // Wait for animation to complete if message wasn't found
    await animationFuture;
    final finalRendered = _isMessageRendered(targetIndex);

    // If target not found and we haven't hit boundary or max retries, continue scrolling
    if (!finalRendered && !reachedBoundary && retryCount < maxRetries) {
      await _scrollTowardsMessage(
        eventId,
        targetIndex,
        retryCount: retryCount + 1,
      );
    }
  }

  int? _findVisibleEventIndex() {
    // First, try to use the tracked visible event
    if (visibleEventId != null) {
      final index = timeline!.events.indexWhere(
        (event) => event.eventId == visibleEventId,
      );
      if (index != -1) return index;
    }

    // Fallback: Find any currently rendered event by scanning the timeline
    // Start from the middle and work outwards for better performance
    final eventsCount = timeline!.events.length;
    final midPoint = eventsCount ~/ 2;

    // Check middle first (most likely to be rendered)
    if (_isMessageRendered(midPoint)) {
      return midPoint;
    }

    // Spiral outwards from middle
    for (var offset = 1; offset < eventsCount; offset++) {
      // Check above middle
      final upperIndex = midPoint - offset;
      if (upperIndex >= 0 && _isMessageRendered(upperIndex)) {
        return upperIndex;
      }

      // Check below middle
      final lowerIndex = midPoint + offset;
      if (lowerIndex < eventsCount && _isMessageRendered(lowerIndex)) {
        return lowerIndex;
      }
    }

    return null;
  }

  /// Checks if a message at [index] is currently rendered.
  bool _isMessageRendered(int index) {
    if (index < 0 || index >= timeline!.events.length) return false;
    final key = GlobalObjectKey(timeline!.events[index].eventId);
    return key.currentContext != null;
  }

  void forgetRoom() async {
    final result = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: room!.forget,
    );
    if (result.error != null) return;
    context.go('/archive');
  }

  void typeEmoji(String emoji) {
    if (emoji.isEmpty) return;
    final text = sendController.text;
    final selection = sendController.selection;
    final newText = sendController.text.isEmpty
        ? emoji
        : text.replaceRange(selection.start, selection.end, emoji);
    sendController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        // don't forget an UTF-8 combined emoji might have a length > 1
        offset: selection.baseOffset + emoji.length,
      ),
    );
    _requestInputFocus();
  }

  void handleStoreRecentReactions(String? emoji) async {
    final emojiId = Matrix.of(context).emojiData.getIdByEmoji(emoji ?? '');

    if (emojiId.isNotEmpty) {
      await storeRecentReactionsInteractor.execute(
        emojiId: emojiId,
      );
    }
  }

  void sendEmojiAction({
    String? emoji,
    required Event event,
  }) async {
    handleStoreRecentReactions(emoji);
    await room!.sendReaction(
      event.eventId,
      emoji!,
    );
  }

  void clearSelectedEvents() {
    showEmojiPickerNotifier.value = false;

    _clearSelectEvent();
  }

  void clearSingleSelectedEvent() {
    if (selectedEvents.length <= 1) {
      clearSelectedEvents();
    }
  }

  void editSelectedEventAction() {
    final client = currentRoomBundle.firstWhere(
      (cl) => selectedEvents.first.senderId == cl!.userID,
      orElse: () => null,
    );
    if (client == null) {
      return;
    }
    setSendingClient(client);
    setState(() {
      pendingText = sendController.text;
      editEventNotifier.value = selectedEvents.first;
    });
    inputText.value = sendController.text = editEventNotifier.value!
        .getDisplayEventWithoutEditEvent(timeline!)
        .calcLocalizedBodyFallback(
          MatrixLocals(L10n.of(context)!),
          withSenderNamePrefix: false,
          hideReply: true,
        );
    _clearSelectEvent();

    _requestInputFocus();
  }

  void goToNewRoomAction() async {
    if (OkCancelResult.ok !=
        await showOkCancelAlertDialog(
          useRootNavigator: false,
          context: context,
          title: L10n.of(context)!.goToTheNewRoom,
          message: room!
              .getState(EventTypes.RoomTombstone)!
              .parsedTombstoneContent
              .body,
          okLabel: L10n.of(context)!.ok,
          cancelLabel: L10n.of(context)!.cancel,
        )) {
      return;
    }
    final result = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () => room!.client.joinRoom(
        room!
            .getState(EventTypes.RoomTombstone)!
            .parsedTombstoneContent
            .replacementRoom,
      ),
    );
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: room!.leave,
    );
    if (result.error == null) {
      context.go('/rooms/${result.result}');
    }
  }

  void onSelectMessage(Event event) {
    if (audioRecordStateNotifier.value != AudioRecordState.initial) {
      preventActionWhileRecordingMobile(context: context);
      return;
    }
    if (!event.redacted) {
      if (selectedEvents.contains(event)) {
        _removeSelectEvent(event);
      } else {
        _addSelectEvent([event]);
      }
      selectedEvents.sort(
        (a, b) => a.originServerTs.compareTo(b.originServerTs),
      );
    }
  }

  int? findChildIndexCallback(Key key, Map<String, int> thisEventsKeyMap) {
    // this method is called very often. As such, it has to be optimized for speed.
    if (key is! ValueKey) {
      return null;
    }
    final eventId = key.value;
    if (eventId is! String) {
      return null;
    }
    // first fetch the last index the event was at
    final index = thisEventsKeyMap[eventId];
    if (index == null) {
      return null;
    }
    // we need to +1 as 0 is the typing thing at the bottom
    return index + 1;
  }

  void onInputBarSubmitted() async {
    await Future.delayed(const Duration(milliseconds: 100));
    await send();
    FocusScope.of(context).requestFocus(inputFocus);
  }

  void unpinEvent(String eventId) async {
    final response = await showOkCancelAlertDialog(
      context: context,
      title: L10n.of(context)!.unpin,
      message: L10n.of(context)!.confirmEventUnpin,
      okLabel: L10n.of(context)!.unpin,
      cancelLabel: L10n.of(context)!.cancel,
    );
    if (response == OkCancelResult.ok) {
      final events = room!.pinnedEventIds
        ..removeWhere((oldEvent) => oldEvent == eventId);
      TwakeDialog.showFutureLoadingDialogFullScreen(
        future: () => room!.setPinnedEvents(events),
      );
    }
  }

  void pinEventAction(Event event) async {
    final room = this.room;
    if (room == null) return;
    final pinnedEventIds = room.pinnedEventIds;
    final selectedEventIds = event.eventId;
    final unpin = isUnpinEvent(event);
    if (unpin) {
      pinnedEventIds.removeWhere(selectedEventIds.contains);
    } else {
      pinnedEventIds.add(selectedEventIds);
    }
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () => room.setPinnedEvents(pinnedEventIds),
    );
    _getPinnedEvents(
      isUnpin: unpin,
      roomId: room.id,
      client: room.client,
      eventId: selectedEventIds,
    );
  }

  Timer? _storeInputTimeoutTimer;
  static const Duration _storeInputTimeout = Duration(milliseconds: 500);

  void onInputBarChanged(String text) {
    if (audioRecordStateNotifier.value != AudioRecordState.initial) {
      return;
    }
    _storeInputTimeoutTimer?.cancel();
    _storeInputTimeoutTimer = Timer(_storeInputTimeout, () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('draft_$roomId', text);
    });
    if (text.endsWith(' ') && matrix!.hasComplexBundles) {
      final clients = currentRoomBundle;
      for (final client in clients) {
        final prefix = client!.sendPrefix;
        if ((prefix.isNotEmpty) &&
            text.toLowerCase() == '${prefix.toLowerCase()} ') {
          setSendingClient(client);
          inputText.value = '';
          setState(() {
            sendController.text = '';
          });
          return;
        }
      }
    }
    typingCoolDown?.cancel();
    typingCoolDown = Timer(const Duration(seconds: 2), () {
      typingCoolDown = null;
      currentlyTyping = false;
      room!.setTyping(false);
    });
    typingTimeout ??= Timer(const Duration(seconds: 30), () {
      typingTimeout = null;
      currentlyTyping = false;
    });
    if (!currentlyTyping) {
      currentlyTyping = true;
      room!
          .setTyping(true, timeout: const Duration(seconds: 30).inMilliseconds);
    }
    inputText.value = text;
  }

  bool get isArchived =>
      {Membership.leave, Membership.ban}.contains(room?.membership);

  void onPhoneButtonTap() async {
    // VoIP required Android SDK 21
    // if (PlatformInfos.isAndroid) {
    //   DeviceInfoPlugin().androidInfo.then((value) {
    //     if (value.version.sdkInt < 21) {
    //       Navigator.pop(context);
    //       showOkAlertDialog(
    //         context: context,
    //         title: L10n.of(context)!.unsupportedAndroidVersion,
    //         message: L10n.of(context)!.unsupportedAndroidVersionLong,
    //         okLabel: L10n.of(context)!.close,
    //       );
    //     }
    //   });
    // }
    // final callType = await showModalActionSheet<CallType>(
    //   context: context,
    //   title: L10n.of(context)!.warning,
    //   message: L10n.of(context)!.videoCallsBetaWarning,
    //   cancelLabel: L10n.of(context)!.cancel,
    //   actions: [
    //     SheetAction(
    //       label: L10n.of(context)!.voiceCall,
    //       icon: Icons.phone_outlined,
    //       key: CallType.kVoice,
    //     ),
    //     SheetAction(
    //       label: L10n.of(context)!.videoCall,
    //       icon: Icons.video_call_outlined,
    //       key: CallType.kVideo,
    //     ),
    //   ],
    // );
    // if (callType == null) return;

    // final success = await TwakeDialog.showFutureLoadingDialogFullScreen(
    //   future: () =>
    //       Matrix.of(context).voipPlugin!.voip.requestTurnServerCredentials(),
    // );
    // if (success.result != null) {
    //   final voipPlugin = Matrix.of(context).voipPlugin;
    //   try {
    //     await voipPlugin!.voip.inviteToCall(room!.id, callType);
    //   } catch (e) {
    //     TwakeSnackBar.show(context, e.toLocalizedString(context));
    //   }
    // } else {
    //   await showOkAlertDialog(
    //     context: context,
    //     title: L10n.of(context)!.unavailable,
    //     okLabel: L10n.of(context)!.next,
    //     useRootNavigator: false,
    //   );
    // }
  }

  void cancelReplyEventAction() => setState(() {
        _updateReplyEvent();
      });

  void cancelEditEventAction() => setState(() {
        if (editEventNotifier.value != null) {
          inputText.value = sendController.text = pendingText;
        }
        editEventNotifier.value = null;
      });

  void onSendFileClick(BuildContext context) async {
    if (PlatformInfos.isMobile) {
      _showMediaPicker(context);
    } else {
      final pendingText = sendController.text;
      final matrixFiles = await pickFilesFromSystem();
      sendController.clear();
      sendFileOnWebAction(
        pendingText: pendingText,
        context,
        room: room,
        matrixFilesList: matrixFiles,
        onSendFileCallback: (result) async {
          await handleSendMediaCallback(
            result: result.status,
            pendingText: pendingText,
          );
        },
      );
    }
  }

  Future<void> handleSendMediaCallback({
    required SendMediaWithCaptionStatus result,
    required String pendingText,
  }) async {
    if (result != SendMediaWithCaptionStatus.done && pendingText.isNotEmpty) {
      sendController.text = pendingText;
    }
    if (result == SendMediaWithCaptionStatus.done) {
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('draft_$roomId');
    }

    scrollDown();
  }

  void _showMediaPicker(BuildContext context) {
    final imagePickerController = ImagePickerGridController(
      AssetCounter(imagePickerMode: ImagePickerMode.multiple),
    );

    if (sendController.text.isNotEmpty) {
      _captionsController.text = sendController.text;
    }

    showMediaPickerBottomSheetAction(
      room: room,
      context: context,
      imagePickerGridController: imagePickerController,
      onPickerTypeTap: (action) => onPickerTypeClick(
        type: action,
        room: room,
        context: context,
        onSendFileCallback: scrollDown,
      ),
      onSendTap: () {
        sendMedia(
          imagePickerController,
          room: room,
          caption: _captionsController.text,
        );
        scrollDown();
        _captionsController.clear();
        sendController.clear();
      },
      onCameraPicked: (_) async {
        sendMedia(imagePickerController, room: room);
        scrollDown();

        // Also add draft cleanup here
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('draft_$roomId');
      },
      captionController: _captionsController,
      focusSuggestionController: _focusSuggestionController,
      typeAheadKey: _chatMediaPickerTypeAheadKey,
    );
  }

  void onHover(bool isHovered, int index, Event event) {
    if (index > 0 &&
        timeline!.events[index - 1].eventId == event.eventId &&
        !responsive.isMobile(context) &&
        !selectMode &&
        !openingPopupMenu.value) {
      focusHover.value = isHovered ? event.eventId : null;
    }
  }

  void _handleStateContextMenu() {
    openingPopupMenu.toggle();
  }

  List<ContextMenuItemChatAction> listHorizontalActionMenuBuilder(
    Event event,
  ) {
    final listAction = [
      if (event.room.canSendReactions) ChatHorizontalActionMenu.reaction,
      if (event.status.isAvailable && event.room.canSendDefaultMessages)
        ChatHorizontalActionMenu.reply,
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

  void handleHorizontalActionMenu(
    BuildContext context,
    ChatHorizontalActionMenu actions,
    Event event,
    TapDownDetails tapDownDetails,
  ) {
    switch (actions) {
      case ChatHorizontalActionMenu.reaction:
        handleReactionEmojiAction(
          context,
          event,
          tapDownDetails,
        );
        break;
      case ChatHorizontalActionMenu.reply:
        replyAction(replyTo: event);
        break;
      case ChatHorizontalActionMenu.forward:
        forwardEventsAction(event: event);
        break;
      case ChatHorizontalActionMenu.more:
        handleContextMenuAction(
          context,
          event,
          tapDownDetails,
        );
        break;
    }
  }

  List<ChatContextMenuActions> _getListPopupMenuActions(Event event) {
    final listAction = [
      if (event.status.isAvailable) ChatContextMenuActions.forward,
      if (event.isCopyable) ChatContextMenuActions.copyMessage,
      if (event.canEditEvents(matrix)) ...[
        ChatContextMenuActions.edit,
      ],
      if (event.room.canReportContent) ChatContextMenuActions.report,
      if (event.room.canPinMessage) ChatContextMenuActions.pinChat,
      if (PlatformInfos.isWeb && event.hasAttachment)
        ChatContextMenuActions.downloadFile,
      ChatContextMenuActions.select,
      if (event.canDelete) ChatContextMenuActions.delete,
    ];
    return listAction;
  }

  List<ContextMenuAction> _mapPopupMenuActionsToContextMenuActions(
    List<ChatContextMenuActions> listActions,
    Event event,
  ) {
    return listActions.map((action) {
      return ContextMenuAction(
        name: action.getTitle(
          context,
          unpin: isUnpinEvent(event),
          isSelected: isSelected(event),
        ),
        icon: action.getIconData(
          unpin: isUnpinEvent(event),
        ),
        imagePath: action.getImagePath(
          unpin: isUnpinEvent(event),
        ),
        colorIcon: action.getIconColor(context, event, action),
        styleName: action == ChatContextMenuActions.delete
            ? PopupMenuWidgetStyle.defaultItemTextStyle(context)?.merge(
                TextStyle(
                  color: LinagoraSysColors.material().error,
                ),
              )
            : null,
      );
    }).toList();
  }

  void _handleClickOnContextMenuItem(
    ChatContextMenuActions action,
    Event event,
  ) {
    switch (action) {
      case ChatContextMenuActions.select:
        onSelectMessage(event);
        break;
      case ChatContextMenuActions.copyMessage:
        event.copy(context, timeline!);
        break;
      case ChatContextMenuActions.pinChat:
        pinEventAction(event);
        break;
      case ChatContextMenuActions.report:
        reportEventAction(event);
        break;
      case ChatContextMenuActions.forward:
        forwardEventsAction(event: event);
        break;
      case ChatContextMenuActions.downloadFile:
        downloadFileAction(context, event);
        break;
      case ChatContextMenuActions.reply:
        replyAction(replyTo: event);
        break;
      case ChatContextMenuActions.delete:
        deleteEventAction(context, event);
        break;
      case ChatContextMenuActions.edit:
        editAction(editEvent: event);
        break;
      default:
        break;
    }
  }

  Future<String?> downloadFileAction(BuildContext context, Event event) async {
    if (audioRecordStateNotifier.value != AudioRecordState.initial) {
      preventActionWhileRecordingMobile(context: context);
      return null;
    }
    return await event.saveFile(context);
  }

  void handleContextMenuAction(
    BuildContext context,
    Event event,
    TapDownDetails tapDownDetails,
  ) async {
    final offset = tapDownDetails.globalPosition;
    final listPopupMenuActions = _getListPopupMenuActions(event);
    final listContextMenuActions = _mapPopupMenuActionsToContextMenuActions(
      listPopupMenuActions,
      event,
    );
    _handleStateContextMenu();
    final selectedActionIndex = await showTwakeContextMenu(
      offset: offset,
      context: context,
      listActions: listContextMenuActions,
      onClose: _handleStateContextMenu,
    );

    if (selectedActionIndex != null && selectedActionIndex is int) {
      _handleClickOnContextMenuItem(
        listPopupMenuActions[selectedActionIndex],
        event,
      );
    }
  }

  void handleReactionEmojiAction(
    BuildContext context,
    Event event,
    TapDownDetails tapDownDetails,
  ) async {
    final offset = tapDownDetails.globalPosition;
    final double positionLeftTap = offset.dx;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double availableRightSpace = screenWidth - positionLeftTap;
    final double positionBottomTap = offset.dy;
    final double heightScreen = MediaQuery.sizeOf(context).height;
    final double availableBottomSpace = heightScreen - positionBottomTap;
    double? positionLeft;
    double? positionRight;
    double? positionTop;
    double? positionBottom;
    Alignment alignment = Alignment.topLeft;

    if (availableRightSpace < defaultMaxWidthReactionPicker) {
      positionRight = screenWidth - positionLeftTap;
      alignment = Alignment.topRight;
    } else {
      positionLeft = positionLeftTap;
    }

    if (availableBottomSpace < defaultMaxHeightReactionPicker) {
      positionBottom = availableBottomSpace;
    } else {
      positionTop = positionBottomTap;
    }
    _handleStateContextMenu();
    final myReaction = event
        .aggregatedEvents(
          timeline!,
          RelationshipTypes.reaction,
        )
        .where(
          (event) =>
              event.senderId == event.room.client.userID &&
              event.type == 'm.reaction',
        )
        .firstOrNull;
    final relatesTo =
        (myReaction?.content as Map<String, dynamic>?)?['m.relates_to'];
    showFullEmojiPickerOnWebNotifier.value = false;
    await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (dialogContext) => GestureDetector(
        onTap: Navigator.of(dialogContext).pop,
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            height: 56,
            width: double.infinity,
            color: Colors.transparent,
            child: Stack(
              children: [
                ValueListenableBuilder(
                  valueListenable: showFullEmojiPickerOnWebNotifier,
                  builder: (context, showFullEmojiPickerOnWeb, child) {
                    return Positioned(
                      left: positionLeft,
                      top: positionTop,
                      bottom: positionBottom,
                      right: positionRight,
                      child: Align(
                        alignment: alignment,
                        child: showFullEmojiPickerOnWeb
                            ? Container(
                                padding: const EdgeInsets.all(12),
                                width: defaultMaxWidthReactionPicker,
                                height: defaultMaxHeightReactionPicker,
                                decoration: BoxDecoration(
                                  color:
                                      LinagoraRefColors.material().primary[100],
                                  borderRadius: BorderRadius.circular(
                                    24,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0x0000004D)
                                          .withOpacity(0.15),
                                      offset: const Offset(0, 4),
                                      blurRadius: 8,
                                      spreadRadius: 3,
                                    ),
                                    BoxShadow(
                                      color: const Color(0x00000026)
                                          .withOpacity(0.3),
                                      offset: const Offset(0, 1),
                                      blurRadius: 3,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: emoji_mart.EmojiPicker(
                                  emojiData: Matrix.of(context).emojiData,
                                  recentEmoji:
                                      getRecentReactionsInteractor.execute(),
                                  configuration:
                                      emoji_mart.EmojiPickerConfiguration(
                                    showRecentTab: true,
                                    emojiStyle: Theme.of(context)
                                        .textTheme
                                        .headlineLarge!,
                                    searchEmptyTextStyle: Theme.of(context)
                                        .textTheme
                                        .labelMedium!
                                        .copyWith(
                                          color: LinagoraRefColors.material()
                                              .tertiary[30],
                                        ),
                                    searchEmptyWidget: SvgPicture.asset(
                                      ImagePaths.icSearchEmojiEmpty,
                                    ),
                                    searchFocusNode: FocusNode(),
                                  ),
                                  itemBuilder: (
                                    context,
                                    emojiId,
                                    emoji,
                                    callback,
                                  ) {
                                    return MouseRegion(
                                      onHover: (_) {},
                                      child: emoji_mart.EmojiItem(
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .headlineLarge!,
                                        onTap: () {
                                          callback(
                                            emojiId,
                                            emoji,
                                          );
                                        },
                                        emoji: emoji,
                                      ),
                                    );
                                  },
                                  onEmojiSelected: (
                                    emojiId,
                                    emoji,
                                  ) async {
                                    final isSelected =
                                        emoji == (relatesTo?['key'] ?? '');
                                    if (myReaction == null) {
                                      Navigator.of(context).pop();
                                      sendEmojiAction(
                                        emoji: emoji,
                                        event: event,
                                      );
                                      return;
                                    }

                                    if (isSelected) {
                                      Navigator.of(context).pop();
                                      await myReaction.redactEvent();
                                      return;
                                    }

                                    if (!isSelected) {
                                      Navigator.of(context).pop();
                                      await myReaction.redactEvent();
                                      sendEmojiAction(
                                        emoji: emoji,
                                        event: event,
                                      );
                                      return;
                                    }
                                  },
                                ),
                              )
                            : ReactionsPicker(
                                emojis: AppConfig.emojisDefault,
                                myEmojiReacted: relatesTo?['key'] ?? '',
                                emojiSize: 40,
                                onPickEmojiReactionAction: () {
                                  showFullEmojiPickerOnWebNotifier.value = true;
                                  openingPopupMenu.value = false;
                                },
                                onClickEmojiReactionAction: (emoji) async {
                                  final isSelected =
                                      emoji == (relatesTo?['key'] ?? '');
                                  if (myReaction == null) {
                                    sendEmojiAction(
                                      emoji: emoji,
                                      event: event,
                                    );
                                    return;
                                  }

                                  if (isSelected) {
                                    await myReaction.redactEvent();
                                    return;
                                  }

                                  if (!isSelected) {
                                    await myReaction.redactEvent();
                                    sendEmojiAction(
                                      emoji: emoji,
                                      event: event,
                                    );
                                    return;
                                  }
                                },
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      openingPopupMenu.value = false;
    });
  }

  void hideKeyboardChatScreen() {
    if (keyboardVisibilityController.isVisible || inputFocus.hasFocus) {
      inputFocus.unfocus();
      rawKeyboardListenerFocusNode.unfocus();
    }
  }

  void onHideKeyboardAndEmoji() {
    hideKeyboardChatScreen();
    if (!PlatformInfos.isWeb) {
      showEmojiPickerNotifier.value = false;
    }
  }

  void onPushDetails() async {
    if (audioRecordStateNotifier.value != AudioRecordState.initial) {
      preventActionWhileRecordingMobile(context: context);
      return null;
    }
    if (room?.isDirectChat == true) {
      return widget.onChangeRightColumnType?.call(RightColumnType.profileInfo);
    } else {
      return widget.onChangeRightColumnType
          ?.call(RightColumnType.groupChatDetails);
    }
  }

  void toggleSearch() {
    if (audioRecordStateNotifier.value != AudioRecordState.initial) {
      preventActionWhileRecordingMobile(context: context);
      return;
    }
    widget.onChangeRightColumnType?.call(RightColumnType.search);
  }

  void actionWithClearSelections(Function action) {
    action();
    clearSelectedEvents();
  }

  void onAcceptInvitation() async {
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        final waitForRoom = room?.client.waitForRoomInSync(
          room!.id,
          join: true,
        );
        await room?.join();
        await waitForRoom;
      },
    ).then((_) => _tryLoadTimeline());
  }

  void onRejectInvitation(BuildContext context) async {
    final result = await showDialog<DialogRejectInviteResult>(
      context: TwakeApp.routerKey.currentContext ?? context,
      useRootNavigator: PlatformInfos.isWeb,
      builder: (c) => const DialogRejectInviteWidget(),
    );

    if (result == null) return;

    switch (result) {
      case DialogRejectInviteResult.cancel:
        return;
      case DialogRejectInviteResult.reject:
        await leaveChat(context, room);
        return;
    }
  }

  String get displayInviterName {
    if (room!.isDirectChat) {
      return room!.getLocalizedDisplayname();
    } else {
      return room!.lastEvent?.senderFromMemoryOrFallback.displayName ??
          room!.getLocalizedDisplayname();
    }
  }

  void _resetLocationPath() {
    final currentLocation = html.window.location.href;

    final event = Uri.tryParse(Uri.tryParse(currentLocation)?.fragment ?? '')
        ?.queryParameters['event'];
    if (event == null) return;
    Logs().d("Chat::_resetLocationPath: CurrentLocation - $currentLocation");
    final queryIndex = currentLocation.indexOf('?');
    final newLocation = queryIndex != -1
        ? currentLocation.substring(0, queryIndex)
        : currentLocation;
    Logs().d("Chat::_resetLocationPath: New - $newLocation");
    html.window.history.replaceState(null, '', newLocation);
  }

  void handlePopBackFromPinnedScreen(Object? popResult) async {
    Logs().d(
      "PinnedEventsController()::handlePopBack(): popResult: $popResult",
    );
    if (popResult is Event) {
      scrollToEventIdAndHighlight(popResult.eventId);
    } else if (popResult is List<Event?>) {
      pinnedEventsController.handlePopBack(
        popResult: popResult,
        client: client,
      );
    }
  }

  void _initializePinnedEvents() {
    if (roomId == null) return;
    _getPinnedEvents(
      client: client,
      roomId: roomId!,
      isInitial: true,
    );
  }

  void _getPinnedEvents({
    required Client client,
    required String roomId,
    bool isInitial = false,
    bool isUnpin = false,
    String? eventId,
  }) {
    pinnedEventsController.getPinnedMessageAction(
      client: client,
      roomId: roomId,
      isInitial: isInitial,
      isUnpin: isUnpin,
      eventId: eventId,
    );
  }

  void handleDisplayStickyTimestamp(DateTime dateTime) {
    if (_currentChatScrollState.isEndScroll) return;
    _currentDateTimeEvent = dateTime;
    stickyTimestampNotifier.value ??= dateTime;
    if (stickyTimestampNotifier.value?.day != dateTime.day) {
      Logs().d(
        'Chat::handleDisplayStickyTimestamp() StickyTimestampNotifier - ${stickyTimestampNotifier.value}',
      );
      Logs().d(
        'Chat::handleDisplayStickyTimestamp() CurrentDateTimeEvent - $_currentDateTimeEvent',
      );
      _updateStickyTimestampNotifier(
        dateTime: dateTime,
      );
    }
  }

  bool isInViewPortCondition(
    double deltaTopReversed,
    double deltaBottomReversed,
    double viewPortDimension,
  ) {
    final stickyTimestampHeight =
        stickyTimestampKey.globalPaintBoundsRect?.height ?? 0;
    return deltaTopReversed < -viewPortDimension + stickyTimestampHeight &&
        deltaBottomReversed > -viewPortDimension + stickyTimestampHeight;
  }

  void _handleHideStickyTimestamp() {
    Logs().d('Chat::_handleHideStickyTimestamp() - Hide sticky timestamp');
    _updateStickyTimestampNotifier();
  }

  void handleScrollEndNotification() {
    Logs().d('Chat::handleScrollEndNotification() - End of scroll');
    if (PlatformInfos.isMobile) {
      _timestampTimer?.cancel();
      _currentChatScrollState = ChatScrollState.endScroll;
      _timestampTimer =
          Timer(_delayHideStickyTimestampHeader, _handleHideStickyTimestamp);
    }
  }

  void handleScrollStartNotification() {
    Logs().d('Chat::handleScrollStartNotification() - Start of scroll');
    if (PlatformInfos.isMobile) _timestampTimer?.cancel();
    _currentChatScrollState = ChatScrollState.startScroll;
  }

  void handleScrollUpdateNotification() {
    _currentChatScrollState = ChatScrollState.scrolling;
  }

  List<String> get getEventTypeToFilterUnnecessaryEvent => [
        EventTypes.Message,
        EventTypes.Encrypted,
        EventTypes.Sticker,
      ];

  Future<void> _tryRequestHistory() async {
    if (timeline == null) return;

    final allMembershipEvents = timeline!.events.every(
      (event) => event.type == EventTypes.RoomMember,
    );

    final canRequestHistory = timeline!.events
            .where((event) => event.isVisibleInGui)
            .toList()
            .length <
        _defaultEventCountDisplay;

    if (allMembershipEvents || canRequestHistory) {
      try {
        await requestHistory(historyCount: _defaultEventCountDisplay)
            .then((response) async {
          Logs().v(
            'Chat::_tryRequestHistory():: Try request history success',
          );
          if (allMembershipEvents) {
            await requestHistory(
              historyCount: _defaultEventCountDisplay,
              filter: StateFilter(
                lazyLoadMembers: true,
                types: getEventTypeToFilterUnnecessaryEvent,
              ),
            );
          }
        });
      } catch (e) {
        Logs().e(
          'Chat::_tryRequestHistory():: Error - $e',
        );
      } finally {
        _updateOpeningChatViewStateNotifier(ViewEventListSuccess());
      }
    } else {
      _updateOpeningChatViewStateNotifier(ViewEventListSuccess());
    }
  }

  void _updateOpeningChatViewStateNotifier(ViewEventListUIState state) {
    try {
      openingChatViewStateNotifier.value = state;
    } on FlutterError catch (e) {
      Logs().e(
        'Chat::_updateViewEventListNotifier():: FlutterError - $e',
      );
    }
  }

  void _requestInputFocus() {
    if (!inputFocus.hasPrimaryFocus) {
      inputFocus.requestFocus();
    }
  }

  void _updateReplyEvent({Event? event}) {
    try {
      replyEventNotifier.value = event;
    } on FlutterError catch (e) {
      Logs().e(
        'Chat::_updateReplyEvent():: FlutterError: $e',
        e.stackTrace,
      );
    }
  }

  void _addSelectEvent(List<Event> events) {
    setState(() {
      selectedEvents.addAll(events);
    });
  }

  void _removeSelectEvent(Event events) {
    setState(() {
      selectedEvents.remove(events);
    });
  }

  void _clearSelectEvent() {
    if (selectedEvents.isEmpty) return;
    setState(() {
      selectedEvents.clear();
    });
  }

  void _listenRoomUpdateEvent() {
    if (room == null) return;
    onUpdateEventStreamSubcription =
        client.onEvent.stream.listen((eventUpdate) async {
      Logs().d(
        'Chat::_listenRoomUpdateEvent():: Event Update Content ${eventUpdate.content}',
      );
      if (room?.id != eventUpdate.roomID) return;
      if (eventUpdate.isPinnedEventsHasChanged) {
        eventUpdate.updatePinnedMessage(
          onPinnedMessageUpdated: _handlePinnedMessageCallBack,
        );
      } else if (isPinnedEventDeleted(eventUpdate)) {
        final events = room!.pinnedEventIds
          ..removeWhere(
            (oldEvent) => oldEvent == eventUpdate.content['redacts'],
          );
        try {
          await room!.setPinnedEvents(events);
        } catch (e) {
          Logs().e('Chat::_listenRoomUpdateEvent():: Error - $e');
        }
      }
    });
  }

  bool isPinnedEventDeleted(EventUpdate eventUpdate) {
    return eventUpdate.content['type'] == EventTypes.Redaction &&
        room?.pinnedEventIds.contains(eventUpdate.content['redacts']) == true;
  }

  void _handlePinnedMessageCallBack({
    required bool isInitial,
    required bool isUnpin,
    String? eventId,
  }) {
    if (roomId == null) return;
    Logs().d(
      'Chat::_handlePinnedMessageCallBack():: eventId - $eventId',
    );
    _getPinnedEvents(
      client: client,
      roomId: roomId!,
      isInitial: isInitial,
      isUnpin: isUnpin,
      eventId: eventId,
    );
  }

  void _updateStickyTimestampNotifier({
    DateTime? dateTime,
  }) {
    try {
      stickyTimestampNotifier.value = dateTime;
    } on FlutterError catch (e) {
      Logs().e(
        'Chat::_updateStickyTimestampNotifier():: FlutterError - $e',
      );
    }
  }

  bool get hasActionAppBarMenu => _getListActionAppBarMenu().isNotEmpty;

  void handleAppbarMenuAction(
    BuildContext context,
    TapDownDetails tapDownDetails,
  ) async {
    if (audioRecordStateNotifier.value != AudioRecordState.initial) {
      preventActionWhileRecordingMobile(context: context);
      return null;
    }
    final offset = tapDownDetails.globalPosition;
    final listAppBarActions = _getListActionAppBarMenu();
    final listContextMenuActions =
        _mapAppbarMenuActionToContextMenuAction(listAppBarActions);

    final selectedActionIndex = await showTwakeContextMenu(
      offset: offset,
      context: context,
      listActions: listContextMenuActions,
    );

    if (selectedActionIndex != null && selectedActionIndex is int) {
      final selectedAction = listAppBarActions[selectedActionIndex];
      onSelectedAppBarActions(selectedAction);
    }
  }

  List<ChatAppBarActions> _getListActionAppBarMenu() {
    return selectMode
        ? _getListActionAppbarMenuSelectMode()
        : _getListActionAppbarMenuNormal();
  }

  List<ChatAppBarActions> _getListActionAppbarMenuSelectMode() {
    return [
      if (PlatformInfos.isAndroid) ...[
        if (selectedEvents.length == 1 &&
            selectedEvents.first.hasAttachment &&
            !selectedEvents.first.isVideoOrImage)
          ChatAppBarActions.saveToDownload,
      ],
      if (selectedEvents.length == 1 &&
          selectedEvents.first.isVideoOrImage &&
          !PlatformInfos.isWeb)
        ChatAppBarActions.saveToGallery,
      ChatAppBarActions.info,
      ChatAppBarActions.report,
    ];
  }

  List<ChatAppBarActions> _getListActionAppbarMenuNormal() {
    return [
      if (!isSupportChat) ChatAppBarActions.leaveGroup,
    ];
  }

  List<ContextMenuAction> _mapAppbarMenuActionToContextMenuAction(
    List<ChatAppBarActions> listAction,
  ) {
    return listAction.map((action) {
      return ContextMenuAction(
        name: action.getTitle(context),
        icon: action.getIcon(),
        colorIcon: action.getColorIcon(context),
        styleName: action == ChatAppBarActions.leaveGroup
            ? PopupMenuWidgetStyle.defaultItemTextStyle(context)?.copyWith(
                color: action.getColorIcon(context),
              )
            : null,
      );
    }).toList();
  }

  void onSelectedAppBarActions(ChatAppBarActions action) {
    switch (action) {
      case ChatAppBarActions.saveToDownload:
        actionWithClearSelections(
          () => saveSelectedEventToDownloadAndroid(
            context,
            selectedEvents.first,
          ),
        );
        break;
      case ChatAppBarActions.saveToGallery:
        actionWithClearSelections(
          () => saveSelectedEventToGallery(context, selectedEvents.first),
        );
        break;
      case ChatAppBarActions.info:
        actionWithClearSelections(
          () => showEventInfo(
            context,
            selectedEvents.single,
          ),
        );
        break;
      case ChatAppBarActions.report:
        actionWithClearSelections(
          () => reportEventAction(selectedEvents.single),
        );
        break;
      case ChatAppBarActions.leaveGroup:
        leaveChat(context, room);
        break;
    }
  }

  void onDisplayEmojiReaction() {
    showEmojiPickerNotifier.value = true;
  }

  void onHideEmojiReaction() {
    showEmojiPickerNotifier.value = false;
    if (inputFocus.hasFocus) {
      FocusScope.of(context).requestFocus(inputFocus);
    }
  }

  void handleOnTapMoreButtonOnWeb(
    BuildContext context,
    Event event,
    TapDownDetails tapDownDetails,
    double chatScreenWidth,
  ) async {
    final offset = tapDownDetails.globalPosition;
    final double positionLeftTap = offset.dx;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double availableRightSpace = screenWidth - positionLeftTap;
    final double availableRightSpaceWithChatScreenWidth =
        chatScreenWidth - positionLeftTap;
    final double positionBottomTap = offset.dy;
    final double heightScreen = MediaQuery.sizeOf(context).height;
    final double availableBottomSpace = heightScreen - positionBottomTap;
    double? positionLeft;
    double? positionRight;
    double? positionTop;
    double? positionBottom;
    Alignment alignment = Alignment.topLeft;

    if (availableRightSpace < defaultMaxWidthReactionPicker ||
        availableRightSpaceWithChatScreenWidth < 0) {
      positionRight = screenWidth - positionLeftTap;
      alignment = Alignment.topRight;
    } else if (availableRightSpace < defaultMaxWidthReactionPicker ||
        availableRightSpaceWithChatScreenWidth > 0) {
      positionRight = screenWidth - positionLeftTap;
    } else {
      positionLeft = positionLeftTap;
    }

    if (availableBottomSpace < defaultMaxHeightReactionPicker) {
      positionBottom = availableBottomSpace;
    } else {
      positionTop = positionBottomTap;
    }
    _handleStateContextMenu();
    final myReaction = event
        .aggregatedEvents(
          timeline!,
          RelationshipTypes.reaction,
        )
        .where(
          (event) =>
              event.senderId == event.room.client.userID &&
              event.type == 'm.reaction',
        )
        .firstOrNull;
    final relatesTo =
        (myReaction?.content as Map<String, dynamic>?)?['m.relates_to'];
    showFullEmojiPickerOnWebNotifier.value = false;
    final listPopupMenuActions = [
      ChatContextMenuActions.select,
      ChatContextMenuActions.reply,
      if (event.status.isAvailable) ChatContextMenuActions.forward,
      if (event.canEditEvents(matrix)) ChatContextMenuActions.edit,
      if (event.isCopyable) ChatContextMenuActions.copyMessage,
      if (event.room.canReportContent) ChatContextMenuActions.report,
      ChatContextMenuActions.pinChat,
      if (PlatformInfos.isWeb && event.hasAttachment)
        ChatContextMenuActions.downloadFile,
      if (event.canRedact) ChatContextMenuActions.delete,
    ];
    final listContextMenuActions = _mapPopupMenuActionsToContextMenuActions(
      listPopupMenuActions,
      event,
    );
    await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (dialogContext) => GestureDetector(
        onTap: Navigator.of(dialogContext).pop,
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            height: 56,
            width: double.infinity,
            color: Colors.transparent,
            child: Stack(
              children: [
                ValueListenableBuilder(
                  valueListenable: showFullEmojiPickerOnWebNotifier,
                  builder: (context, showFullEmojiPickerOnWeb, child) {
                    return Positioned(
                      left: positionLeft,
                      top: positionTop,
                      bottom: positionBottom,
                      right: positionRight,
                      child: Align(
                        alignment: alignment,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            showFullEmojiPickerOnWeb
                                ? Container(
                                    padding: const EdgeInsets.all(12),
                                    width: 326,
                                    height: 360,
                                    decoration: BoxDecoration(
                                      color: LinagoraRefColors.material()
                                          .primary[100],
                                      borderRadius: BorderRadius.circular(
                                        24,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0x0000004D)
                                              .withOpacity(0.15),
                                          offset: const Offset(0, 4),
                                          blurRadius: 8,
                                          spreadRadius: 3,
                                        ),
                                        BoxShadow(
                                          color: const Color(0x00000026)
                                              .withOpacity(0.3),
                                          offset: const Offset(0, 1),
                                          blurRadius: 3,
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: emoji_mart.EmojiPicker(
                                      emojiData: Matrix.of(context).emojiData,
                                      recentEmoji: getRecentReactionsInteractor
                                          .execute(),
                                      configuration:
                                          emoji_mart.EmojiPickerConfiguration(
                                        showRecentTab: true,
                                        emojiStyle: Theme.of(context)
                                            .textTheme
                                            .headlineLarge!,
                                        searchEmptyTextStyle: Theme.of(context)
                                            .textTheme
                                            .labelMedium!
                                            .copyWith(
                                              color:
                                                  LinagoraRefColors.material()
                                                      .tertiary[30],
                                            ),
                                        searchEmptyWidget: SvgPicture.asset(
                                          ImagePaths.icSearchEmojiEmpty,
                                        ),
                                        searchFocusNode: FocusNode(),
                                      ),
                                      itemBuilder: (
                                        context,
                                        emojiId,
                                        emoji,
                                        callback,
                                      ) {
                                        return MouseRegion(
                                          onHover: (_) {},
                                          child: emoji_mart.EmojiItem(
                                            textStyle: Theme.of(context)
                                                .textTheme
                                                .headlineLarge!,
                                            onTap: () {
                                              callback(
                                                emojiId,
                                                emoji,
                                              );
                                            },
                                            emoji: emoji,
                                          ),
                                        );
                                      },
                                      onEmojiSelected: (
                                        emojiId,
                                        emoji,
                                      ) async {
                                        final isSelected =
                                            emoji == (relatesTo?['key'] ?? '');
                                        if (myReaction == null) {
                                          Navigator.of(context).pop();
                                          sendEmojiAction(
                                            emoji: emoji,
                                            event: event,
                                          );
                                          return;
                                        }

                                        if (isSelected) {
                                          Navigator.of(context).pop();
                                          await myReaction.redactEvent();
                                          return;
                                        }

                                        if (!isSelected) {
                                          Navigator.of(context).pop();
                                          await myReaction.redactEvent();
                                          sendEmojiAction(
                                            emoji: emoji,
                                            event: event,
                                          );
                                          return;
                                        }
                                      },
                                    ),
                                  )
                                : ReactionsPicker(
                                    emojis: AppConfig.emojisDefault,
                                    myEmojiReacted: relatesTo?['key'] ?? '',
                                    emojiSize: 40,
                                    onPickEmojiReactionAction: () {
                                      showFullEmojiPickerOnWebNotifier.value =
                                          true;
                                      openingPopupMenu.value = false;
                                    },
                                    onClickEmojiReactionAction: (emoji) async {
                                      final isSelected =
                                          emoji == (relatesTo?['key'] ?? '');
                                      if (myReaction == null) {
                                        sendEmojiAction(
                                          emoji: emoji,
                                          event: event,
                                        );
                                        return;
                                      }

                                      if (isSelected) {
                                        await myReaction.redactEvent();
                                        return;
                                      }

                                      if (!isSelected) {
                                        await myReaction.redactEvent();
                                        sendEmojiAction(
                                          emoji: emoji,
                                          event: event,
                                        );
                                        return;
                                      }
                                    },
                                  ),
                            const SizedBox(height: 8),
                            Offstage(
                              offstage: showFullEmojiPickerOnWeb,
                              child: Card(
                                elevation: TwakeContextMenuStyle.menuElevation,
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    TwakeContextMenuStyle.menuBorderRadius,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    TwakeContextMenuStyle.menuBorderRadius,
                                  ),
                                  child: Material(
                                    color:
                                        TwakeContextMenuStyle.defaultMenuColor(
                                      context,
                                    ),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minWidth:
                                            TwakeContextMenuStyle.menuMinWidth,
                                        maxWidth:
                                            TwakeContextMenuStyle.menuMaxWidth,
                                      ),
                                      child: IntrinsicWidth(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: TwakeContextMenuStyle
                                                .defaultVerticalPadding,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: listContextMenuActions
                                                .map(
                                                  (action) =>
                                                      ContextMenuActionItemWidget(
                                                    action: action,
                                                    closeMenuAction: () {
                                                      Navigator.of(
                                                        dialogContext,
                                                      ).pop();
                                                      _handleClickOnContextMenuItem(
                                                        listPopupMenuActions[
                                                            listContextMenuActions
                                                                .indexOf(
                                                          action,
                                                        )],
                                                        event,
                                                      );
                                                    },
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      openingPopupMenu.value = false;
    });
  }

  void listenIgnoredUser() {
    isBlockedUserNotifier.value = room?.isDirectChat == true &&
        client.ignoredUsers.contains(user?.id ?? '');
    ignoredUsersStreamSub = client.ignoredUsersStream.listen((value) {
      isBlockedUserNotifier.value = room?.isDirectChat == true &&
          client.ignoredUsers.contains(user?.id ?? '');
    });
  }

  StreamSubscription? keyboardVisibilitySubscription;

  void onLongPressAudioRecordInMobile() {
    handleLongPressAudioRecordInMobile(
      context: context,
    );
  }

  void disposeAudioPlayer() {
    if (PlatformInfos.isMobile) {
      return;
    }
    disposeAudioMixin();
    matrix?.audioPlayer.stop();
    matrix?.audioPlayer.clearAudioSources();
    matrix?.voiceMessageEvent.value = null;
  }

  void initAudioPlayer() {
    if (matrix?.audioPlayer.playing == true) {
      if (!PlatformInfos.isMobile) {
        matrix?.audioPlayer
          ?..stop()
          ..dispose();
      }
      // On mobile, keep audio playing and return early
      return;
    }
    if (matrix?.voiceMessageEvent != null) {
      matrix?.voiceMessageEvent.value = null;
    }

    if (matrix?.currentAudioStatus.value != AudioPlayerStatus.notDownloaded) {
      matrix?.currentAudioStatus.value = AudioPlayerStatus.notDownloaded;
    }
  }

  void _listenOnJumpToEventFromSearch() {
    _jumpToEventFromSearchSubscription =
        widget.jumpToEventStream?.listen((eventId) {
      Logs().d(
        'Chat::_listenOnJumpToEventFromSearch(): Jump to eventId from search: $eventId',
      );
      scrollToEventIdAndHighlight(eventId);
    });
  }

  @override
  void onSendFileCallback() => scrollDown();

  void _emojiPickerListener() {
    if (!showEmojiPickerComposerNotifier.value) {
      searchEmojiFocusNode.unfocus();
      if (!inputFocus.hasFocus) {
        inputFocus.requestFocus();
      }
    } else {
      inputFocus.unfocus();
      searchEmojiFocusNode.requestFocus();
    }
  }

  @override
  void initState() {
    super.initState();
    _initializePinnedEvents();
    _listenOnJumpToEventFromSearch();
    registerPasteShortcutListeners();
    keyboardVisibilitySubscription =
        keyboardVisibilityController.onChange.listen(_keyboardListener);
    scrollController.addListener(_updateScrollController);
    _loadDraft();
    _tryLoadTimeline();
    sendController.addListener(updateInputTextNotifier);
    initAutoMarkAsReadMixin();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (room == null) {
        return context.go("/error");
      }
      _handleReceivedShareFiles();
      _listenRoomUpdateEvent();
      initCachedPresence();
      await _requestParticipants();
      listenIgnoredUser();
      if (PlatformInfos.isWeb) {
        initAudioRecorderWeb();
      }
      initAudioPlayer();
    });
    showEmojiPickerComposerNotifier.addListener(_emojiPickerListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    matrix = Matrix.of(context);
  }

  @override
  void didUpdateWidget(covariant Chat oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentLocation = html.window.location.href;

    final highlightEventId =
        Uri.tryParse(Uri.tryParse(currentLocation)?.fragment ?? '')
            ?.queryParameters['event'];
    if (highlightEventId != null) {
      scrollToEventId(highlightEventId, highlight: true);
    }
  }

  @override
  void dispose() {
    unregisterPasteShortcutListeners();
    disposeAutoMarkAsReadMixin();
    timeline?.cancelSubscriptions();
    timeline = null;
    inputFocus.dispose();
    searchEmojiFocusNode.dispose();
    composerDebouncer.cancel();
    focusSuggestionController.dispose();
    _focusSuggestionController.dispose();
    _jumpToEventIdSubscription?.cancel();
    _jumpToEventFromSearchSubscription?.cancel();
    pinnedEventsController.dispose();
    _captionsController.dispose();
    scrollController.removeListener(_updateScrollController);
    scrollController.dispose();
    keyboardFocus.dispose();
    chatFocusNode.dispose();
    rawKeyboardListenerFocusNode.dispose();
    suggestionScrollController.dispose();
    sendController.removeListener(updateInputTextNotifier);
    sendController.dispose();
    suggestionsController.dispose();
    stickyTimestampNotifier.dispose();
    openingChatViewStateNotifier.dispose();
    draggingNotifier.dispose();
    showEmojiPickerNotifier.dispose();
    pinnedMessageScrollController.dispose();
    onUpdateEventStreamSubcription?.cancel();
    keyboardVisibilitySubscription?.cancel();
    replyEventNotifier.dispose();
    cachedPresenceStreamController.close();
    cachedPresenceNotifier.dispose();
    showFullEmojiPickerOnWebNotifier.dispose();
    showEmojiPickerComposerNotifier.removeListener(_emojiPickerListener);
    showEmojiPickerComposerNotifier.dispose();
    disposeUnblockUserSubscription();
    isBlockedUserNotifier.dispose();
    ignoredUsersStreamSub?.cancel();
    cachedPresenceStreamSubscription?.cancel();
    sendingClient = null;
    showScrollDownButtonNotifier.dispose();
    editEventNotifier.dispose();
    focusHover.dispose();
    disposeAudioPlayer();
    super.dispose();
  }

  @override
  final TextEditingController sendController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (_) => _resetLocationPath(),
      child: ChatView(this),
    );
  }
}

enum EmojiPickerType { reaction, keyboard }
