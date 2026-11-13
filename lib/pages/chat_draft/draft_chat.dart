import 'dart:async';

import 'package:collection/collection.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:twake_chat/domain/direct_chat/exceptions/create_direct_chat_exception.dart';
import 'package:twake_chat/domain/direct_chat/usecases/create_direct_chat_usecase.provider.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_controller.dart';
import 'package:twake_chat/presentation/extensions/contact/unified_contact_extension.dart';
import 'package:twake_chat/domain/model/extensions/xfile/xfile_extension.dart';
import 'package:twake_chat/domain/model/file_info/file_info.dart';
import 'package:twake_chat/domain/reactions/usecases/get_recent_reactions_usecase.dart';
import 'package:twake_chat/domain/reactions/usecases/get_recent_reactions_usecase.provider.dart';
import 'package:twake_chat/domain/reactions/usecases/store_recent_reactions_usecase.provider.dart';
import 'package:twake_chat/domain/usecase/room/send_text_message_interactor.dart';
import 'package:twake_chat/pages/chat/chat.dart';
import 'package:twake_chat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:twake_chat/pages/chat/providers/chat_providers.dart';
import 'package:twake_chat/pages/chat_draft/draft_chat_view.dart';
import 'package:twake_chat/presentation/enum/chat/right_column_type_enum.dart';
import 'package:twake_chat/presentation/widget_keys/widget_keys.dart';
import 'package:twake_chat/presentation/enum/chat/send_media_with_caption_status_enum.dart';
import 'package:twake_chat/presentation/extensions/send_file_extension.dart';
import 'package:twake_chat/presentation/extensions/send_file_fake_event_extension.dart';
import 'package:twake_chat/presentation/extensions/send_file_web_extension.dart';
import 'package:twake_chat/presentation/mixins/audio_mixin.dart';
import 'package:twake_chat/presentation/mixins/common_media_picker_mixin.dart';
import 'package:twake_chat/presentation/mixins/media_picker_mixin.dart';
import 'package:twake_chat/presentation/mixins/send_files_mixin.dart';
import 'package:twake_chat/presentation/mixins/unblock_user_mixin.dart';
import 'package:twake_chat/presentation/model/chat/chat_router_input_argument.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.provider.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:twake_chat/utils/recent_reactions_extension.dart';
import 'package:twake_chat/domain/model/room/room_extension.dart';
import 'package:twake_chat/pages/contacts_tab/providers/unified_contact_read_providers.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/mixins/drag_drog_file_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart'
    show Category, EmojiData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/providers/emoji_data_provider.dart';
import 'package:linagora_design_flutter/images_picker/asset_counter.dart';
import 'package:linagora_design_flutter/images_picker/images_picker.dart'
    hide ImagePicker;
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

typedef OnRoomCreatedSuccess = FutureOr<void> Function(Room room)?;
typedef OnRoomCreatedFailed = FutureOr<void> Function()?;
typedef OnSendFileClick = void Function(BuildContext context);
typedef OnInputBarSubmitted = void Function();
typedef OnEmojiAction = void Function(TapDownDetails details);
typedef OnKeyboardAction = void Function();
typedef OnInputBarChanged = void Function(String text);

class DraftChat extends ConsumerStatefulWidget {
  final PresentationContact contact;

  final void Function(RightColumnType)? onChangeRightColumnType;

  const DraftChat({
    super.key,
    required this.contact,
    this.onChangeRightColumnType,
  });

  @override
  DraftChatController createState() => DraftChatController();
}

class DraftChatController extends ConsumerState<DraftChat>
    with
        CommonMediaPickerMixin,
        MediaPickerMixin,
        SendFilesMixin,
        DragDrogFileMixin,
        UnblockUserMixin,
        AudioMixin {
  EmojiData get emojiData => ref.read(emojiDataProvider).requireValue;

  Client get client => Matrix.read(context).client;

  late final UploadManager uploadManager = ref.read(uploadManagerProvider);

  late final GetRecentReactionsUseCase _getRecentReactions;

  final AutoScrollController scrollController = AutoScrollController();
  final AutoScrollController forwardListController = AutoScrollController();

  final FocusSuggestionController focusSuggestionController =
      FocusSuggestionController();

  int _createRoomRequestId = 0;

  final ValueKey<String> draftChatComposerTypeAheadKey =
      ChatKeys.draftComposerTypeAhead.valueKey;

  final ValueKey<String> _draftChatMediaPickerTypeAheadKey =
      ChatKeys.draftMediaPickerTypeAhead.valueKey;

  FocusNode inputFocus = FocusNode();
  FocusNode keyboardFocus = FocusNode();

  bool showScrollDownButton = false;

  ValueNotifier<String> inputText = ValueNotifier('');

  ValueNotifier<bool> showEmojiPickerComposerNotifier = ValueNotifier(false);

  final ValueNotifier<UnifiedContact?> _userProfile = ValueNotifier(null);

  EmojiPickerType emojiPickerType = EmojiPickerType.keyboard;

  final isSendingNotifier = ValueNotifier(false);

  final TextEditingController _captionsController = TextEditingController();

  late PresentationContact presentationContact;

  final KeyboardVisibilityController keyboardVisibilityController =
      KeyboardVisibilityController();

  void _updateScrollController() {
    if (!mounted) {
      return;
    }
    if (!scrollController.hasClients) return;
    if (scrollController.position.pixels > 0 && showScrollDownButton == false) {
      setState(() => showScrollDownButton = true);
    } else if (scrollController.position.pixels == 0 &&
        showScrollDownButton == true) {
      setState(() => showScrollDownButton = false);
    }
  }

  List<IndexedAssetEntity> sortedSelectedAssets = [];

  void onLongPressAudioRecordInMobile() {
    handleLongPressAudioRecordInMobile(context: context);
  }

  @override
  Future<void> sendMedia(
    ImagePickerGridController imagePickerController, {
    String? caption,
    Room? room,
    Event? inReplyTo,
  }) {
    sendController.clear();
    return _createRoom(
      onRoomCreatedSuccess: (newRoom) {
        super.sendMedia(
          imagePickerController,
          room: newRoom,
          caption: caption,
          inReplyTo: inReplyTo,
        );
      },
    );
  }

  void handleDragDone(DropDoneDetails details) async {
    draggingNotifier.value = false;
    final matrixFilesList = await super.onDragDone(details);
    if (!mounted) return;

    _handleSendFileOnWeb(context, matrixFilesList);
  }

  ProviderSubscription<AsyncValue<List<UnifiedContact>>>? _contactsSubscription;

  ProviderContainer? _tryContainer() {
    try {
      return ProviderScope.containerOf(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  void _onTomContactsUpdateListener() {
    final matrixId = presentationContact.matrixId;
    final contact = _tryContainer()
        ?.read(contactsControllerProvider)
        .asData
        ?.value
        .firstWhereOrNull((c) => c.matrixId == matrixId);
    final updatedContact = contact?.toPresentationContact();
    if (mounted && updatedContact != null) {
      setState(() {
        presentationContact = updatedContact;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getRecentReactions = ref.read(getRecentReactionsUseCaseProvider);
    presentationContact = widget.contact;
    _contactsSubscription = _tryContainer()?.listen(
      contactsControllerProvider,
      (previous, next) {
        next.whenData((_) => _onTomContactsUpdateListener());
      },
    );
    scrollController.addListener(_updateScrollController);
    keyboardVisibilityController.onChange.listen(_keyboardListener);
    if (PlatformInfos.isWeb) {
      initAudioRecorderWeb();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getProfile();
    });
  }

  @override
  void dispose() {
    _contactsSubscription?.close();
    scrollController.dispose();
    sendController.dispose();
    forwardListController.dispose();
    focusSuggestionController.dispose();
    inputText.dispose();
    showEmojiPickerComposerNotifier.dispose();
    _userProfile.dispose();
    isSendingNotifier.dispose();
    inputFocus.dispose();
    keyboardFocus.dispose();
    disposeUnblockUserSubscription();
    _captionsController.dispose();
    disposeAudioMixin();
    draggingNotifier.dispose();
    super.dispose();
  }

  TextEditingController sendController = TextEditingController();

  Future<String> _triggerTagGreetingMessage() async {
    if (_userProfile.value == null) {
      return sendController.value.text;
    } else {
      final displayName = _userProfile.value?.resolvedDisplayName;
      if (sendController.value.text.contains(displayName ?? '') == true) {
        return sendController.value.text.replaceAll(
          "${displayName ?? ''}!",
          presentationContact.matrixId ?? '',
        );
      } else {
        return sendController.value.text;
      }
    }
  }

  bool isInsideContactManager(List<UnifiedContact> contacts) => contacts.any(
    (contact) =>
        contact.isAddressBookContact &&
        contact.matrixId == (presentationContact.matrixId ?? ''),
  );
  final showAddContactBanner = ValueNotifier(true);

  Future<void> sendVoiceMessageWeb() async {
    _createRoom(
      onRoomCreatedSuccess: (room) async {
        final duration = Duration(seconds: recordDurationWebNotifier.value);
        final path = await stopRecordWeb();
        final file = await recordToFileOnWeb(blobUrl: path);

        if (file == null) return;

        final matrixFile = await createMatrixAudioFileFromWebFile(
          file: file,
          duration: duration,
        );

        if (matrixFile == null) return;

        final fileInfo = FileInfo(matrixFile.name, bytes: matrixFile.bytes);

        final txid = client.generateUniqueTransactionId();

        room.sendingFilePlaceholders[txid] = matrixFile;

        final extraContent = {
          'info': {...matrixFile.info, 'duration': duration.inMilliseconds},
          'org.matrix.msc3245.voice': {},
          'org.matrix.msc1767.audio': {
            'duration': duration.inMilliseconds,
            'waveform': convertWaveformWeb(),
          },
        };

        final fakeImageEvent = await room.sendFakeFileInfoEvent(
          fileInfo,
          txid: txid,
          messageType: MessageTypes.Audio,
          extraContent: extraContent,
        );

        await room
            .sendFileOnWebEvent(
              matrixFile,
              txid: txid,
              fakeImageEvent: fakeImageEvent,
              extraContent: extraContent,
            )
            .catchError((e) {
              Logs().e('Failed to send voice message', e);
              return null;
            });
      },
    );
  }

  Future<void> sendVoiceMessageAction({
    required TwakeAudioFile audioFile,
    required Duration time,
    required List<int> waveform,
  }) async {
    _createRoom(
      onRoomCreatedSuccess: (room) async {
        final fileInfo = FileInfo(audioFile.name, bytes: audioFile.bytes);

        final txid = client.generateUniqueTransactionId();

        final fakeImageEvent = await room.sendFakeFileInfoEvent(
          fileInfo,
          txid: txid,
          messageType: MessageTypes.Audio,
        );

        await room
            .sendFileEventMobile(
              fileInfo,
              txid: txid,
              msgType: MessageTypes.Audio,
              fakeImageEvent: fakeImageEvent,
              extraContent: {
                'info': {...audioFile.info, 'duration': time.inMilliseconds},
                'org.matrix.msc3245.voice': {},
                'org.matrix.msc1767.audio': {
                  'duration': time.inMilliseconds,
                  'waveform': waveform,
                },
              },
            )
            .catchError((e) {
              TwakeSnackBar.show(
                context,
                L10n.of(context)!.audioMessageFailedToSend,
              );
              Logs().e('Failed to send voice message', e);
              return null;
            });
      },
    );
  }

  Future<void> sendText({OnRoomCreatedFailed onCreateRoomFailed}) async {
    final SendTextMessageInteractor sendTextMessageInteractor = ref.read(
      sendTextMessageInteractorProvider,
    );
    scrollDown();
    sendController.value = TextEditingValue(
      text: sendController.value.text,
      selection: const TextSelection.collapsed(offset: 0),
    );
    inputFocus.unfocus();
    final textEvent = await _triggerTagGreetingMessage();
    _createRoom(
      onRoomCreatedSuccess: (room) => unawaited(
        sendTextMessageInteractor.execute(room: room, text: textEvent),
      ),
      onRoomCreatedFailed: onCreateRoomFailed,
    );
  }

  Future<void> _createRoom({
    OnRoomCreatedSuccess onRoomCreatedSuccess,
    OnRoomCreatedFailed onRoomCreatedFailed,
  }) async {
    // Every sender (text, media, voice) blocks the screen until it ends.
    isSendingNotifier.value = true;
    // Only the latest request reports back, as the cancelled stream did.
    final requestId = ++_createRoomRequestId;
    final intendedMxId = presentationContact.matrixId!;
    // One client for the whole request: the use case captures it on read.
    final client = ref.read(activeMatrixClientProvider);
    String? roomId;
    CreateDirectChatException? failure;
    try {
      roomId = await ref
          .read(createDirectChatUseCaseProvider)
          .execute(contactMxId: intendedMxId);
    } on CreateDirectChatException catch (e) {
      failure = e;
    } catch (e, s) {
      // Not a typed failure (an Error or a missing client): the screen must not
      // stay blocked, and the cause is reported instead of hidden.
      Logs().e('_createRoom: unexpected failure', e, s);
      failure = CreateDirectChatFailedException(e);
    }
    if (!mounted || requestId != _createRoomRequestId) return;

    if (!identical(ref.read(activeMatrixClientProvider), client)) {
      // The account changed during the request: its room is not ours to open.
      isSendingNotifier.value = false;
      return;
    }
    if (failure is CreateDirectChatRoomMismatchException) {
      _refuseRoom();
      return;
    }
    if (failure != null) {
      onRoomCreatedFailed?.call();
      Logs().d('_createRoom: $failure');
      isSendingNotifier.value = false;
      return;
    }
    // Only the legacy success callback needs the Room itself.
    final room = client?.getRoomById(roomId!);
    if (room == null) {
      _refuseRoom();
      return;
    }
    onRoomCreatedSuccess?.call(room);
    RoomRoute(
      roomid: room.id,
      $extra: ChatRouterInputArgument(
        type: ChatRouterInputArgumentType.draft,
        data:
            _userProfile.value?.resolvedDisplayName ??
            presentationContact.displayName ??
            room.name,
      ),
    ).go(context);
  }

  void _refuseRoom() {
    isSendingNotifier.value = false;
    TwakeSnackBar.show(context, L10n.of(context)!.roomCreationFailed);
  }

  void onEmojiAction(TapDownDetails details) {
    if (PlatformInfos.isMobile) return;

    inputFocus.requestFocus();

    showEmojiPickerComposerNotifier.value = true;
  }

  void scrollDown() {
    if (scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
  }

  Future<Category?> getRecentEmoji() => _getRecentReactions.recentCategory();

  void typeEmoji(String emoji) {
    if (emoji.isEmpty) return;
    final emojiId = emojiData.getIdByEmoji(emoji);

    unawaited(
      ref
          .read(storeRecentReactionsUseCaseProvider)
          .executeOrLog(emojiId: emojiId),
    );
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
    inputFocus.requestFocus();
  }

  void emojiPickerBackspace() {
    sendController
      ..text = sendController.text.characters.skipLast(1).toString()
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: sendController.text.length),
      );

    if (PlatformInfos.isWeb) {
      inputFocus.requestFocus();
    }
  }

  void onInputBarSubmitted() {
    sendText(
      onCreateRoomFailed: () {
        TwakeSnackBar.show(context, L10n.of(context)!.roomCreationFailed);
        inputFocus.requestFocus();
      },
    );
  }

  void onInputBarChanged(String text) {
    inputText.value = text;
  }

  void onSendFileClick(BuildContext context) async {
    if (PlatformInfos.isWeb) {
      sendFileOnWebAction(context);
    } else {
      _showMediaPicker(context);
    }
  }

  void _showMediaPicker(BuildContext context) {
    final imagePickerController = ImagePickerGridController(
      AssetCounter(imagePickerMode: ImagePickerMode.multiple),
    );

    if (sendController.text.isNotEmpty) {
      _captionsController.text = sendController.text;
    }

    showMediaPickerBottomSheetAction(
      context: context,
      imagePickerGridController: imagePickerController,
      captionController: _captionsController,
      onPickerTypeTap: (action) =>
          onPickerTypeClick(type: action, context: context),
      onSendTap: () => sendMedia(imagePickerController),
      onCameraPicked: (_) => sendMedia(imagePickerController),
      typeAheadKey: _draftChatMediaPickerTypeAheadKey,
    );
  }

  void sendFileOnWebAction(BuildContext context, {Room? room}) async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;

    final matrixFilesList = await _convertFilesToMatrixFiles(
      result.xFiles,
      (file) async => (await file.toMatrixFileOnWeb()).detectFileType,
    );
    if (!mounted) return;
    _handleSendFileOnWeb(context, matrixFilesList);
  }

  Future<List<MatrixFile>> _convertFilesToMatrixFiles<T>(
    Iterable<T> files,
    Future<MatrixFile> Function(T file) convert,
  ) async {
    final matrixFilesList = await Future.wait(
      files.map((file) async {
        try {
          return await convert(file);
        } catch (e) {
          return null;
        }
      }),
    );

    return matrixFilesList.nonNulls.toList();
  }

  Future<void> _handleSendFileOnWeb(
    BuildContext context,
    List<MatrixFile> matrixFilesList,
  ) async {
    if (matrixFilesList.isEmpty) {
      TwakeSnackBar.show(context, L10n.of(context)!.failedToSendFiles);
      return;
    }

    final pendingText = sendController.text;
    sendController.clear();

    final dialogResult = await sendImagesWithCaption(
      context: context,
      matrixFiles: matrixFilesList,
      pendingText: pendingText,
    );
    if (!mounted) return;

    if (dialogResult != null) {
      _handleSendFileDialogStatus(
        dialogResult.status,
        matrixFilesList,
        dialogResult.caption ?? '',
      );

      if (dialogResult.status != SendMediaWithCaptionStatus.emptyRoom &&
          pendingText.isNotEmpty) {
        sendController.text = pendingText;
      }
    }
  }

  void _handleSendFileDialogStatus(
    SendMediaWithCaptionStatus status,
    List<MatrixFile> matrixFilesList,
    String? caption,
  ) {
    switch (status) {
      case SendMediaWithCaptionStatus.cancel:
        break;
      case SendMediaWithCaptionStatus.done:
      case SendMediaWithCaptionStatus.emptyRoom:
        _createRoom(
          onRoomCreatedSuccess: (newRoom) {
            if (matrixFilesList.first is MatrixImageFile) {
              uploadManager.uploadFilesWeb(
                room: newRoom,
                files: [matrixFilesList.first],
                caption: caption,
              );
            } else {
              uploadManager.uploadFilesWeb(
                room: newRoom,
                files: matrixFilesList,
                caption: caption,
              );
            }
          },
        );
        break;
    }
  }

  void onPushDetails() {
    widget.onChangeRightColumnType?.call(RightColumnType.profileInfo);
  }

  Future<void> handleDraftAction(BuildContext context) async {
    inputFocus.requestFocus();
    sendController.value = TextEditingValue(
      text: L10n.of(context)!.draftChatHookPhrase(
        _userProfile.value?.resolvedDisplayName ??
            presentationContact.displayName ??
            '',
      ),
    );
    onInputBarChanged(sendController.text);
  }

  Future<void> _getProfile() async {
    try {
      // SDK access goes through Riverpod (transitional container read).
      final profile = await ProviderScope.containerOf(
        context,
        listen: false,
      ).read(contactDisplayProvider(presentationContact.matrixId!).future);
      _userProfile.value = profile;
    } catch (e) {
      Logs().e('Error _getProfile profile: $e');
      _userProfile.value = null;
    }
  }

  void hideKeyboardChatScreen() {
    if (keyboardVisibilityController.isVisible || inputFocus.hasFocus) {
      inputFocus.unfocus();
    }
  }

  void _keyboardListener(bool isKeyboardVisible) {}

  @override
  Widget build(BuildContext context) {
    return DraftChatView(controller: this);
  }
}
