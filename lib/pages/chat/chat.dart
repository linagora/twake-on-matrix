import 'dart:async';
import 'dart:io';
import 'package:fluffychat/pages/chat/chat_view_style.dart';
import 'package:fluffychat/presentation/mixins/handle_clipboard_action_mixin.dart';
import 'package:fluffychat/presentation/mixins/paste_image_mixin.dart';
import 'package:universal_html/html.dart' as html;

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:collection/collection.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/usecase/room/chat_get_pinned_events_interactor.dart';
import 'package:fluffychat/domain/usecase/send_file_interactor.dart';
import 'package:fluffychat/pages/chat/chat_context_menu_actions.dart';
import 'package:fluffychat/pages/chat/chat_horizontal_action_menu.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_events_controller.dart';
import 'package:fluffychat/pages/chat/chat_view.dart';
import 'package:fluffychat/pages/chat/context_item_chat_action.dart';
import 'package:fluffychat/pages/chat/dialog_reject_invite_widget.dart';
import 'package:fluffychat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:fluffychat/pages/chat/recording_dialog.dart';
import 'package:fluffychat/presentation/enum/chat/right_column_type_enum.dart';
import 'package:fluffychat/presentation/mixins/common_media_picker_mixin.dart';
import 'package:fluffychat/presentation/mixins/go_to_direct_chat_mixin.dart';
import 'package:fluffychat/presentation/mixins/media_picker_mixin.dart';
import 'package:fluffychat/presentation/mixins/send_files_mixin.dart';
import 'package:fluffychat/presentation/mixins/send_files_with_caption_web_mixin.dart';
import 'package:fluffychat/presentation/model/forward/forward_argument.dart';
import 'package:fluffychat/utils/account_bundles.dart';
import 'package:fluffychat/utils/adaptive_bottom_sheet.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/network_connection_service.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/mixins/drag_drog_file_mixin.dart';
import 'package:fluffychat/widgets/mixins/popup_context_menu_action_mixin.dart';
import 'package:fluffychat/widgets/mixins/popup_menu_widget_mixin.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linagora_design_flutter/images_picker/asset_counter.dart';
import 'package:linagora_design_flutter/images_picker/images_picker_grid.dart';
import 'package:matrix/matrix.dart';
import 'package:record/record.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'send_file_dialog.dart';
import 'sticker_picker_dialog.dart';

class Chat extends StatefulWidget {
  final String roomId;
  final List<MatrixFile?>? shareFiles;
  final String? roomName;
  final void Function(RightColumnType)? onChangeRightColumnType;

  const Chat({
    Key? key,
    required this.roomId,
    this.shareFiles,
    this.roomName,
    this.onChangeRightColumnType,
  }) : super(key: key);

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
        HandleClipboardActionMixin {
  final NetworkConnectionService networkConnectionService =
      getIt.get<NetworkConnectionService>();

  static const double _isPortionAvailableToScroll = 64;

  final responsive = getIt.get<ResponsiveUtils>();

  final getPinnedMessageInteractor = getIt.get<ChatGetPinnedEventsInteractor>();

  PinnedEventsController pinnedEventsController = PinnedEventsController();

  final ValueKey chatComposerTypeAheadKey =
      const ValueKey('chatComposerTypeAheadKey');

  final ValueKey _chatMediaPickerTypeAheadKey =
      const ValueKey('chatMediaPickerTypeAheadKey');

  @override
  Room? room;

  Client? sendingClient;

  Timeline? timeline;

  MatrixState? matrix;

  String _markerReadLocation = '';

  String? unreadReceivedMessageLocation;

  List<MatrixFile?>? get shareFiles => widget.shareFiles;

  String? get roomName => widget.roomName;

  String? get roomId => widget.roomId;

  final composerDebouncer =
      Debouncer<String>(const Duration(milliseconds: 100), initialValue: '');

  bool get isEmptyChat =>
      timeline != null &&
      !timeline!.events.any(
        (event) => {
          EventTypes.Message,
          EventTypes.Sticker,
          EventTypes.Encrypted,
          EventTypes.CallInvite,
        }.contains(event.type),
      );

  final AutoScrollController scrollController = AutoScrollController();

  final KeyboardVisibilityController keyboardVisibilityController =
      KeyboardVisibilityController();

  final ValueNotifier<String?> focusHover = ValueNotifier(null);

  final ValueNotifier<bool> openingPopupMenu = ValueNotifier(false);

  final ValueNotifier<bool> showScrollDownButtonNotifier = ValueNotifier(false);

  final ValueNotifier<bool> showEmojiPickerNotifier = ValueNotifier(false);

  final FocusSuggestionController _focusSuggestionController =
      FocusSuggestionController();

  final TextEditingController _captionsController = TextEditingController();

  FocusNode inputFocus = FocusNode();

  FocusNode keyboardFocus = FocusNode();

  FocusNode selectionFocusNode = FocusNode();

  @override
  FocusNode chatFocusNode = FocusNode();

  String selectionText = "";

  Timer? typingCoolDown;
  Timer? typingTimeout;
  bool currentlyTyping = false;

  StreamSubscription<EventId>? _jumpToEventIdSubscription;

  bool get canSaveSelectedEvent =>
      selectedEvents.length == 1 &&
      {
        MessageTypes.Video,
        MessageTypes.Image,
        MessageTypes.Sticker,
        MessageTypes.Audio,
        MessageTypes.File,
      }.contains(selectedEvents.single.messageType);

  List<Event> selectedEvents = [];

  final Set<String> unfolded = {};

  Event? replyEvent;

  Event? editEvent;

  bool get selectMode => selectedEvents.isNotEmpty;

  Client get client => Matrix.of(context).client;

  final int _loadHistoryCount = 100;

  final inputText = ValueNotifier('');

  String pendingText = '';

  ScrollController suggestionScrollController = ScrollController();

  bool isUnpinEvent(Event event) =>
      room?.pinnedEventIds
          .firstWhereOrNull((eventId) => eventId == event.eventId) !=
      null;

  void updateInputTextNotifier() {
    inputText.value = sendController.text;
  }

  String? _findUnreadReceivedMessageLocation() {
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

  Future<void> leaveChat() async {
    final room = this.room;
    if (room == null) {
      throw Exception(
        'Leave room button clicked while room is null. This should not be possible from the UI!',
      );
    }
    final success = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: room.leave,
    );
    if (success.error != null) return;
    context.go('/rooms');
  }

  EmojiPickerType emojiPickerType = EmojiPickerType.keyboard;

  void requestHistory() async {
    if (!timeline!.canRequestHistory) return;
    Logs().v('Chat::requestHistory(): Requesting history...');
    try {
      await timeline!.requestHistory(historyCount: _loadHistoryCount);
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

  void _updateScrollController() {
    if (!mounted) {
      return;
    }
    if (!scrollController.hasClients) return;
    if (timeline?.allowNewEvent == false ||
        scrollController.position.pixels > 0) {
      showScrollDownButtonNotifier.value = true;
    } else if (scrollController.position.pixels <= 0) {
      showScrollDownButtonNotifier.value = false;
    }

    if (scrollController.position.pixels == 0 ||
        scrollController.position.pixels == _isPortionAvailableToScroll) {
      requestFuture();
    } else if (scrollController.position.pixels ==
            scrollController.position.maxScrollExtent ||
        scrollController.position.pixels + _isPortionAvailableToScroll ==
            scrollController.position.maxScrollExtent) {
      requestHistory();
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

  void _keyboardListener(bool isKeyboardVisible) {
    if (isKeyboardVisible && showEmojiPickerNotifier.value == true) {
      showEmojiPickerNotifier.value = false;
    }
  }

  void handleDragDone(DropDoneDetails details) async {
    final matrixFiles = await onDragDone(details);
    sendFileOnWebAction(context, room: room, matrixFilesList: matrixFiles);
  }

  void _handleReceivedShareFiles() {
    if (shareFiles != null && room != null) {
      final sendFileInteractor = getIt.get<SendFileInteractor>();
      final filesIsNotNull = shareFiles!.where((file) => file != null);
      sendFileInteractor.execute(
        room: room!,
        fileInfos: filesIsNotNull
            .map((file) => FileInfo.fromMatrixFile(file!))
            .toList(),
      );
    }
  }

  void _initUnreadLocation(String fullyRead) {
    _markerReadLocation = fullyRead;
    unreadReceivedMessageLocation = _findUnreadReceivedMessageLocation();
    scrollToEventId(fullyRead);
  }

  void _tryLoadTimeline() async {
    loadTimelineFuture = _getTimeline();
    try {
      await loadTimelineFuture?.then((_) {
        _initializePinnedEvents();
      });
      final fullyRead = room?.fullyRead;
      if (fullyRead == null || fullyRead.isEmpty || fullyRead == '') {
        setReadMarker();
        return;
      }
      if (room?.hasNewMessages == true) {
        _initUnreadLocation(fullyRead);
        Future.delayed(const Duration(seconds: 5), () {
          setReadMarker(eventId: room?.lastEvent?.eventId);
        });
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

  void setReadMarker({String? eventId}) {
    if (room == null) return;
    if (_setReadMarkerFuture != null) return;
    if (eventId == null &&
        !room!.hasNewMessages &&
        room!.notificationCount == 0) {
      return;
    }
    if (!Matrix.of(context).webHasFocus) return;

    final timeline = this.timeline;
    if (timeline == null || timeline.events.isEmpty) return;

    Logs().d('Set read marker...', eventId);
    // ignore: unawaited_futures
    _setReadMarkerFuture = timeline.setReadMarker(eventId: eventId).then((_) {
      _setReadMarkerFuture = null;
    });
    if (eventId == null || eventId == timeline.room.lastEvent?.eventId) {
      Matrix.of(context).backgroundPush?.cancelNotification(roomId!);
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

  void setActiveClient(Client c) => setState(() {
        Matrix.of(context).setActiveClient(c);
      });

  Future<void> send() async {
    scrollDown();

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
      inReplyTo: replyEvent,
      editEventId: editEvent?.eventId,
      parseCommands: parseCommands,
    );
    sendController.value = TextEditingValue(
      text: pendingText,
      selection: const TextSelection.collapsed(offset: 0),
    );
    setReadMarker();
    inputText.value = pendingText;
    setState(() {
      replyEvent = null;
      editEvent = null;
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

  void voiceMessageAction() async {
    // ignore: unused_local_variable
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (PlatformInfos.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      if (info.version.sdkInt < 19) {
        showOkAlertDialog(
          context: context,
          title: L10n.of(context)!.unsupportedAndroidVersion,
          message: L10n.of(context)!.unsupportedAndroidVersionLong,
          okLabel: L10n.of(context)!.close,
        );
        return;
      }
    }

    if (await Record().hasPermission() == false) return;
    final result = await showDialog<RecordingResult>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (c) => const RecordingDialog(),
    );
    if (result == null) return;
    final audioFile = File(result.path);
    // ignore: unused_local_variable
    final file = MatrixAudioFile(
      bytes: audioFile.readAsBytesSync(),
      name: audioFile.path,
    );
    // await room!.sendFileEvent(
    //   file,
    //   inReplyTo: replyEvent,
    //   extraContent: {
    //     'info': {
    //       ...file.info,
    //       'duration': result.duration,
    //     },
    //     'org.matrix.msc3245.voice': {},
    //     'org.matrix.msc1767.audio': {
    //       'duration': result.duration,
    //       'waveform': result.waveform,
    //     },
    //   },
    // ).catchError((e) {
    //   scaffoldMessenger.showSnackBar(
    //     SnackBar(
    //       content: Text(
    //         (e as Object).toLocalizedString(context),
    //       ),
    //     ),
    //   );
    //   return null;
    // });
    setState(() {
      replyEvent = null;
    });
  }

  void emojiPickerAction() {
    if (showEmojiPickerNotifier.value) {
      inputFocus.requestFocus();
    } else {
      inputFocus.unfocus();
    }
    emojiPickerType = EmojiPickerType.keyboard;
    showEmojiPickerNotifier.toggle();
  }

  void _inputFocusListener() {
    if (showEmojiPickerNotifier.value && inputFocus.hasFocus) {
      emojiPickerType = EmojiPickerType.keyboard;
      showEmojiPickerNotifier.value = true;
    }
  }

  void copySingleEventAction() async {
    if (selectedEvents.length == 1) {
      await selectedEvents.first.copy(context, timeline!);
    }
  }

  void copyEventsAction(Event event, {String? copiedText}) async {
    await event.copyTextEvent(context, timeline!);

    showEmojiPickerNotifier.value = false;
    setState(() {
      selectedEvents.clear();
    });
  }

  void reportEventAction() async {
    final event = selectedEvents.single;
    final score = await showConfirmationDialog<int>(
      context: context,
      title: L10n.of(context)!.reportMessage,
      message: L10n.of(context)!.howOffensiveIsThisContent,
      cancelLabel: L10n.of(context)!.cancel,
      okLabel: L10n.of(context)!.ok,
      actions: [
        AlertDialogAction(
          key: -100,
          label: L10n.of(context)!.extremeOffensive,
        ),
        AlertDialogAction(
          key: -50,
          label: L10n.of(context)!.offensive,
        ),
        AlertDialogAction(
          key: 0,
          label: L10n.of(context)!.inoffensive,
        ),
      ],
    );
    if (score == null) return;
    final reason = await showTextInputDialog(
      useRootNavigator: false,
      context: context,
      title: L10n.of(context)!.whyDoYouWantToReportThis,
      okLabel: L10n.of(context)!.ok,
      cancelLabel: L10n.of(context)!.cancel,
      textFields: [DialogTextField(hintText: L10n.of(context)!.reason)],
    );
    if (reason == null || reason.single.isEmpty) return;
    final result = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () => Matrix.of(context).client.reportContent(
            event.roomId!,
            event.eventId,
            reason: reason.single,
            score: score,
          ),
    );
    if (result.error != null) return;
    showEmojiPickerNotifier.value = false;
    setState(() {
      selectedEvents.clear();
    });
    TwakeSnackBar.show(context, L10n.of(context)!.contentHasBeenReported);
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
    setState(() {
      selectedEvents.clear();
    });
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
          !(clients!.any((cl) => event.senderId == cl!.userID))) return false;
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

  void forwardEventsAction() async {
    if (selectedEvents.length == 1) {
      Matrix.of(context).shareContent =
          selectedEvents.first.getDisplayEvent(timeline!).content;
      Logs().d(
        "forwardEventsAction():: shareContent: ${Matrix.of(context).shareContent}",
      );
    } else {
      Matrix.of(context).shareContentList = selectedEvents
          .map((msg) => msg.getDisplayEvent(timeline!).content)
          .toList();
      Logs().d(
        "forwardEventsAction():: shareContentList: ${Matrix.of(context).shareContentList}",
      );
    }
    setState(() => selectedEvents.clear());
    context.go(
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
    setState(() => selectedEvents.clear());
  }

  void replyAction({Event? replyTo}) {
    setState(() {
      replyEvent = replyTo ?? selectedEvents.first;
      selectedEvents.clear();
    });
    inputFocus.requestFocus();
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
      setReadMarker(eventId: timeline.events.first.eventId);
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
  }) async {
    await Matrix.of(context).client.roomsLoading;
    await Matrix.of(context).client.accountDataLoading;
    if (eventContextId != null &&
        (!eventContextId.isValidMatrixId || eventContextId.sigil != '\$')) {
      eventContextId = null;
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
    timeline!.requestKeys(onlineKeyBackupOnly: false);
    if (room!.markedUnread) room?.markUnread(false);

    // when the scroll controller is attached we want to scroll to an event id, if specified
    // and update the scroll controller...which will trigger a request history, if the
    // "load more" button is visible on the screen
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final event = GoRouterState.of(context).uri.queryParameters['event'];
        if (event != null) {
          scrollToEventId(event, highlight: true);
        }
      }
    });

    return;
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
      scrollController.jumpTo(0);
    }
  }

  int getDisplayEventIndex(int eventIndex) {
    const addedHeadItemsInChat = 1;
    return eventIndex + addedHeadItemsInChat;
  }

  Future<void> scrollToEventId(String eventId, {bool highlight = false}) async {
    final eventIndex = timeline!.events.indexWhere((e) => e.eventId == eventId);
    if (eventIndex == -1) {
      timeline = null;
      loadTimelineFuture = _getTimeline(eventContextId: eventId).onError(
        (e, s) {
          Logs().e('Chat::scrollToEventId(): Unable to load timeline', e, s);
        },
      );
      await loadTimelineFuture;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        scrollToEventId(eventId, highlight: highlight);
      });
      setState(() {});
      return;
    }
    await scrollToIndex(getDisplayEventIndex(eventIndex), highlight: highlight);
    _updateScrollController();
  }

  Future scrollToIndex(int index, {bool highlight = false}) async {
    await scrollController.scrollToIndex(
      index,
      preferPosition: AutoScrollPosition.middle,
    );
    if (highlight) {
      await scrollController.highlight(
        index,
      );
    }
    setState(() {});
  }

  void onEmojiSelected(_, Emoji? emoji) {
    switch (emojiPickerType) {
      case EmojiPickerType.reaction:
        senEmojiReaction(emoji);
        break;
      case EmojiPickerType.keyboard:
        typeEmoji(emoji);
        onInputBarChanged(sendController.text);
        break;
    }
  }

  void senEmojiReaction(Emoji? emoji) {
    showEmojiPickerNotifier.value = false;
    if (emoji == null) return;
    // make sure we don't send the same emoji twice
    if (_allReactionEvents.any((e) {
      final relatedTo = e.content['m.relates_to'];
      return relatedTo is Map &&
          relatedTo.containsKey('key') &&
          relatedTo['key'] == emoji.emoji;
    })) return;
    return sendEmojiAction(emoji.emoji);
  }

  void forgetRoom() async {
    final result = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: room!.forget,
    );
    if (result.error != null) return;
    context.go('/archive');
  }

  void typeEmoji(Emoji? emoji) {
    if (emoji == null) return;
    final text = sendController.text;
    final selection = sendController.selection;
    final newText = sendController.text.isEmpty
        ? emoji.emoji
        : text.replaceRange(selection.start, selection.end, emoji.emoji);
    sendController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        // don't forget an UTF-8 combined emoji might have a length > 1
        offset: selection.baseOffset + emoji.emoji.length,
      ),
    );
  }

  late Iterable<Event> _allReactionEvents;

  void emojiPickerBackspace() {
    switch (emojiPickerType) {
      case EmojiPickerType.reaction:
        showEmojiPickerNotifier.value = false;
        break;
      case EmojiPickerType.keyboard:
        sendController
          ..text = sendController.text.characters.skipLast(1).toString()
          ..selection = TextSelection.fromPosition(
            TextPosition(offset: sendController.text.length),
          );
        break;
    }
  }

  void pickEmojiReactionAction(Iterable<Event> allReactionEvents) async {
    _allReactionEvents = allReactionEvents;
    emojiPickerType = EmojiPickerType.reaction;
    showEmojiPickerNotifier.value = true;
  }

  void sendEmojiAction(String? emoji) async {
    final events = List<Event>.from(selectedEvents);
    setState(() => selectedEvents.clear());
    for (final event in events) {
      await room!.sendReaction(
        event.eventId,
        emoji!,
      );
    }
  }

  void clearSelectedEvents() {
    showEmojiPickerNotifier.value = false;

    setState(() {
      selectedEvents.clear();
    });
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
      editEvent = selectedEvents.first;
      inputText.value = sendController.text =
          editEvent!.getDisplayEvent(timeline!).calcLocalizedBodyFallback(
                MatrixLocals(L10n.of(context)!),
                withSenderNamePrefix: false,
                hideReply: true,
              );
      selectedEvents.clear();
    });
    inputFocus.requestFocus();
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
    if (!event.redacted) {
      if (selectedEvents.contains(event)) {
        setState(
          () => selectedEvents.remove(event),
        );
      } else {
        setState(
          () => selectedEvents.add(event),
        );
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

  void onInputBarSubmitted(_) async {
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
    pinnedEventsController.getPinnedMessageAction(
      isInitial: unpin,
      room: room,
      eventId: selectedEventIds,
    );
  }

  Timer? _storeInputTimeoutTimer;
  static const Duration _storeInputTimeout = Duration(milliseconds: 500);

  void onInputBarChanged(String text) {
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
    if (PlatformInfos.isAndroid) {
      DeviceInfoPlugin().androidInfo.then((value) {
        if (value.version.sdkInt < 21) {
          Navigator.pop(context);
          showOkAlertDialog(
            context: context,
            title: L10n.of(context)!.unsupportedAndroidVersion,
            message: L10n.of(context)!.unsupportedAndroidVersionLong,
            okLabel: L10n.of(context)!.close,
          );
        }
      });
    }
    final callType = await showModalActionSheet<CallType>(
      context: context,
      title: L10n.of(context)!.warning,
      message: L10n.of(context)!.videoCallsBetaWarning,
      cancelLabel: L10n.of(context)!.cancel,
      actions: [
        SheetAction(
          label: L10n.of(context)!.voiceCall,
          icon: Icons.phone_outlined,
          key: CallType.kVoice,
        ),
        SheetAction(
          label: L10n.of(context)!.videoCall,
          icon: Icons.video_call_outlined,
          key: CallType.kVideo,
        ),
      ],
    );
    if (callType == null) return;

    final success = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () =>
          Matrix.of(context).voipPlugin!.voip.requestTurnServerCredentials(),
    );
    if (success.result != null) {
      final voipPlugin = Matrix.of(context).voipPlugin;
      try {
        await voipPlugin!.voip.inviteToCall(room!.id, callType);
      } catch (e) {
        TwakeSnackBar.show(context, e.toLocalizedString(context));
      }
    } else {
      await showOkAlertDialog(
        context: context,
        title: L10n.of(context)!.unavailable,
        okLabel: L10n.of(context)!.next,
        useRootNavigator: false,
      );
    }
  }

  void cancelReplyEventAction() => setState(() {
        if (editEvent != null) {
          inputText.value = sendController.text = pendingText;
          pendingText = '';
        }
        replyEvent = null;
        editEvent = null;
      });

  void onSendFileClick(BuildContext context) async {
    if (PlatformInfos.isMobile) {
      _showMediaPicker(context);
    } else {
      final matrixFiles = await pickFilesFromSystem();
      sendFileOnWebAction(context, room: room, matrixFilesList: matrixFiles);
    }
  }

  void _showMediaPicker(BuildContext context) {
    final imagePickerController = ImagePickerGridController(
      AssetCounter(imagePickerMode: ImagePickerMode.multiple),
    );

    showMediaPickerBottomSheetAction(
      room: room,
      context: context,
      imagePickerGridController: imagePickerController,
      onPickerTypeTap: (action) => onPickerTypeClick(
        type: action,
        room: room,
        context: context,
      ),
      onSendTap: () {
        sendMedia(
          imagePickerController,
          room: room,
          caption: _captionsController.text,
        );
        _captionsController.clear();
      },
      onCameraPicked: (_) => sendMedia(imagePickerController, room: room),
      captionController: _captionsController,
      focusSuggestionController: _focusSuggestionController,
      typeAheadKey: _chatMediaPickerTypeAheadKey,
    );
  }

  void onHover(bool isHovered, int index, Event event) {
    if (index > 0 &&
        timeline!.events[index - 1].eventId == event.eventId &&
        responsive.isDesktop(context) &&
        !selectMode &&
        !openingPopupMenu.value) {
      focusHover.value = isHovered ? event.eventId : null;
    }
  }

  void _handleStateContextMenu() {
    openingPopupMenu.toggle();
  }

  List<ContextMenuItemChatAction> listHorizontalActionMenuBuilder() {
    final listAction = [
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
    PointerDownEvent pointerDownEvent,
  ) {
    switch (actions) {
      case ChatHorizontalActionMenu.reply:
        replyAction(replyTo: event);
        break;
      case ChatHorizontalActionMenu.forward:
        onSelectMessage(event);
        forwardEventsAction();
        break;
      case ChatHorizontalActionMenu.more:
        handleContextMenuAction(
          context,
          event,
          pointerDownEvent,
        );
        break;
    }
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
            unpin: isUnpinEvent(event),
          ),
          iconAction: action.getIcon(
            unpin: isUnpinEvent(event),
          ),
          onCallbackAction: () => _handleClickOnContextMenuItem(
            action,
            event,
          ),
        ),
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
        onSelectMessage(event);
        copySingleEventAction();
        break;
      case ChatContextMenuActions.pinChat:
        pinEventAction(event);
        break;
      case ChatContextMenuActions.forward:
        onSelectMessage(event);
        forwardEventsAction();
        break;
      case ChatContextMenuActions.downloadFile:
        downloadFileAction(context, event);
        break;
    }
  }

  Future<String?> downloadFileAction(BuildContext context, Event event) async =>
      await event.saveFile(context);

  void handleContextMenuAction(
    BuildContext context,
    Event event,
    PointerDownEvent pointerDownEvent,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final offset = pointerDownEvent.position;
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

  void hideKeyboardChatScreen() {
    if (keyboardVisibilityController.isVisible || inputFocus.hasFocus) {
      inputFocus.unfocus();
    }
  }

  void handleOnClickKeyboardAction() {
    showEmojiPickerNotifier.toggle();
    inputFocus.requestFocus();
  }

  void onPushDetails() async {
    if (room?.isDirectChat == true) {
      return widget.onChangeRightColumnType?.call(RightColumnType.profileInfo);
    } else {
      return widget.onChangeRightColumnType
          ?.call(RightColumnType.groupChatDetails);
    }
  }

  void toggleSearch() {
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
    );
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
        await leaveChat();
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
    final queryParameters =
        GoRouterState.of(context).uri.queryParameters['event'];
    Logs().d("Chat::_resetLocationPath: QueryParameters - $queryParameters");
    if (queryParameters == null) return;
    final currentLocation = html.window.location.href;
    Logs().d("Chat::_resetLocationPath: CurrentLocation - $currentLocation");
    final queryIndex = currentLocation.indexOf('?');
    final newLocation = queryIndex != -1
        ? currentLocation.substring(0, queryIndex)
        : currentLocation;
    Logs().d("Chat::_resetLocationPath: New - $newLocation");
    html.window.location.href = newLocation;
  }

  void handlePopBackFromPinnedScreen(Object? popResult) async {
    Logs().d(
      "PinnedEventsController()::handlePopBack(): popResult: $popResult",
    );
    if (popResult is Event) {
      scrollToEventIdAndHighlight(popResult.eventId);
    } else if (popResult is List<Event?>) {
      pinnedEventsController.handlePopBack(popResult);
    }
  }

  void _initializePinnedEvents() {
    pinnedEventsController.getPinnedMessageAction(
      room: room!,
      isInitial: true,
    );
  }

  @override
  void initState() {
    registerPasteShortcutListeners();
    keyboardVisibilityController.onChange.listen(_keyboardListener);
    scrollController.addListener(_updateScrollController);
    inputFocus.addListener(_inputFocusListener);
    _loadDraft();
    _tryLoadTimeline();
    sendController.addListener(updateInputTextNotifier);
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (room == null) {
        return context.go("/error");
      }
      _handleReceivedShareFiles();
    });
  }

  @override
  void didUpdateWidget(covariant Chat oldWidget) {
    super.didUpdateWidget(oldWidget);
    final highlightEventId =
        GoRouterState.of(context).uri.queryParameters['event'];
    if (highlightEventId != null) {
      scrollToEventId(highlightEventId, highlight: true);
    }
  }

  @override
  void dispose() {
    unregisterPasteShortcutListeners();
    timeline?.cancelSubscriptions();
    timeline = null;
    inputFocus.removeListener(_inputFocusListener);
    focusSuggestionController.dispose();
    _jumpToEventIdSubscription?.cancel();
    pinnedEventsController.dispose();
    _captionsController.dispose();
    sendController.removeListener(updateInputTextNotifier);
    sendController.dispose();
    super.dispose();
  }

  @override
  final TextEditingController sendController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (_) => _resetLocationPath(),
      child: ChatView(this, key: widget.key),
    );
  }
}

enum EmojiPickerType { reaction, keyboard }
