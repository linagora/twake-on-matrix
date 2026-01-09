import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/direct_chat/create_direct_chat_success.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/domain/model/extensions/xfile/xfile_extension.dart';
import 'package:fluffychat/domain/model/file_info/file_info.dart';
import 'package:fluffychat/domain/usecase/create_direct_chat_interactor.dart';
import 'package:fluffychat/domain/usecase/reactions/get_recent_reactions_interactor.dart';
import 'package:fluffychat/domain/usecase/reactions/store_recent_reactions_interactor.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_view.dart';
import 'package:fluffychat/presentation/enum/chat/right_column_type_enum.dart';
import 'package:fluffychat/presentation/enum/chat/send_media_with_caption_status_enum.dart';
import 'package:fluffychat/presentation/extensions/client_extension.dart';
import 'package:fluffychat/presentation/extensions/contact/presentation_contact_extension.dart';
import 'package:fluffychat/presentation/extensions/send_file_extension.dart';
import 'package:fluffychat/presentation/extensions/send_file_web_extension.dart';
import 'package:fluffychat/presentation/mixins/audio_mixin.dart';
import 'package:fluffychat/presentation/mixins/common_media_picker_mixin.dart';
import 'package:fluffychat/presentation/mixins/media_picker_mixin.dart';
import 'package:fluffychat/presentation/mixins/send_files_mixin.dart';
import 'package:fluffychat/presentation/mixins/unblock_user_mixin.dart';
import 'package:fluffychat/presentation/model/chat/chat_router_input_argument.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/utils/manager/upload_manager/upload_manager.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:fluffychat/utils/network_connection_service.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/mixins/drag_drog_file_mixin.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';
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

class DraftChat extends StatefulWidget {
  final PresentationContact contact;

  final void Function(RightColumnType)? onChangeRightColumnType;

  const DraftChat({
    super.key,
    required this.contact,
    this.onChangeRightColumnType,
  });

  @override
  State<StatefulWidget> createState() => DraftChatController();
}

class DraftChatController extends State<DraftChat>
    with
        CommonMediaPickerMixin,
        MediaPickerMixin,
        SendFilesMixin,
        DragDrogFileMixin,
        UnblockUserMixin,
        AudioMixin {
  Client get client => Matrix.read(context).client;

  final createDirectChatInteractor = getIt.get<CreateDirectChatInteractor>();

  final getRecentReactionsInteractor =
      getIt.get<GetRecentReactionsInteractor>();

  final storeRecentReactionsInteractor =
      getIt.get<StoreRecentReactionsInteractor>();

  final NetworkConnectionService networkConnectionService =
      getIt.get<NetworkConnectionService>();

  final uploadManager = getIt.get<UploadManager>();

  final AutoScrollController scrollController = AutoScrollController();
  final AutoScrollController forwardListController = AutoScrollController();

  final FocusSuggestionController focusSuggestionController =
      FocusSuggestionController();

  StreamSubscription? _createRoomSubscription;

  final ValueKey draftChatComposerTypeAheadKey =
      const ValueKey('draftChatComposerTypeAheadKey');

  final ValueKey _draftChatMediaPickerTypeAheadKey =
      const ValueKey('draftChatMediaPickerTypeAheadKey');

  final ValueNotifier<bool> isBlockedUserNotifier = ValueNotifier(false);

  StreamSubscription? ignoredUsersStreamSub;

  FocusNode inputFocus = FocusNode();
  FocusNode keyboardFocus = FocusNode();

  bool showScrollDownButton = false;

  ValueNotifier<String> inputText = ValueNotifier('');

  ValueNotifier<bool> showEmojiPickerComposerNotifier = ValueNotifier(false);

  final ValueNotifier<Profile?> _userProfile = ValueNotifier(null);

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
    handleLongPressAudioRecordInMobile(
      context: context,
    );
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
    final matrixFilesList = await super.onDragDone(details);

    _handleSendFileOnWeb(context, matrixFilesList);
  }

  void _onTomContactsUpdateListener() {
    final matrixId = presentationContact.matrixId;
    final getContactsState = getIt.get<ContactsManager>().getContactsNotifier();
    final updatedContact = getContactsState.value.fold(
      (failure) => null,
      (success) {
        if (success is! GetContactsSuccess) return null;

        return success.contacts
            .firstWhereOrNull(
              (c) => c.emails?.any((e) => e.matrixId == matrixId) == true,
            )
            ?.toPresentationContacts()
            .firstOrNull;
      },
    );
    if (mounted && updatedContact != null) {
      setState(() {
        presentationContact = updatedContact;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    presentationContact = widget.contact;
    getIt.get<ContactsManager>().getContactsNotifier().addListener(
          _onTomContactsUpdateListener,
        );
    scrollController.addListener(_updateScrollController);
    keyboardVisibilityController.onChange.listen(_keyboardListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getProfile();
      listenIgnoredUser();
      if (PlatformInfos.isWeb) {
        initAudioRecorderWeb();
      }
    });
  }

  @override
  void dispose() {
    getIt.get<ContactsManager>().getContactsNotifier().removeListener(
          _onTomContactsUpdateListener,
        );
    scrollController.dispose();
    sendController.dispose();
    forwardListController.dispose();
    _createRoomSubscription?.cancel();
    focusSuggestionController.dispose();
    inputText.dispose();
    showEmojiPickerComposerNotifier.dispose();
    _userProfile.dispose();
    isSendingNotifier.dispose();
    inputFocus.dispose();
    keyboardFocus.dispose();
    disposeUnblockUserSubscription();
    ignoredUsersStreamSub?.cancel();
    isBlockedUserNotifier.dispose();
    _captionsController.dispose();
    disposeAudioMixin();
    super.dispose();
  }

  bool get isBlockedUser => Matrix.of(context)
      .client
      .ignoredUsers
      .contains(widget.contact.matrixId ?? '');

  void listenIgnoredUser() {
    isBlockedUserNotifier.value = isBlockedUser;
    ignoredUsersStreamSub =
        Matrix.of(context).client.ignoredUsersStream.listen((value) {
      isBlockedUserNotifier.value = isBlockedUser;
    });
  }

  TextEditingController sendController = TextEditingController();

  Future<String> _triggerTagGreetingMessage() async {
    if (_userProfile.value == null) {
      return sendController.value.text;
    } else {
      final displayName = _userProfile.value?.displayName;
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

  bool isInsideContactManager(Either<Failure, Success> state) => state.fold(
        (failure) => false,
        (success) => success is GetContactsSuccess
            ? success.contacts.any(
                (contact) => contact
                    .inTomAddressBook(presentationContact.matrixId ?? ""),
              )
            : false,
      );
  final showAddContactBanner = ValueNotifier(true);

  Future<void> sendVoiceMessageWeb() async {
    _createRoom(
      onRoomCreatedSuccess: (room) async {
        final duration = Duration(seconds: recordDurationWebNotifier.value);
        final path = await stopRecordWeb();
        final file = await recordToFileOnWeb(
          blobUrl: path,
        );

        if (file == null) return;

        final matrixFile = await createMatrixAudioFileFromWebFile(
          file: file,
          duration: duration,
        );

        if (matrixFile == null) return;

        final fileInfo = FileInfo(
          matrixFile.name,
          bytes: matrixFile.bytes,
        );

        final txid = client.generateUniqueTransactionId();

        room.sendingFilePlaceholders[txid] = matrixFile;

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
        final fileInfo = FileInfo(
          audioFile.name,
          bytes: audioFile.bytes,
        );

        final txid = client.generateUniqueTransactionId();

        final fakeImageEvent = await room.sendFakeFileInfoEvent(
          fileInfo,
          txid: txid,
          messageType: MessageTypes.Audio,
        );

        await room.sendFileEventMobile(
          fileInfo,
          txid: txid,
          msgType: MessageTypes.Audio,
          fakeImageEvent: fakeImageEvent,
          extraContent: {
            'info': {
              ...audioFile.info,
              'duration': time.inMilliseconds,
            },
            'org.matrix.msc3245.voice': {},
            'org.matrix.msc1767.audio': {
              'duration': time.inMilliseconds,
              'waveform': waveform,
            },
          },
        ).catchError((e) {
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

  Future<void> sendText({
    OnRoomCreatedFailed onCreateRoomFailed,
  }) async {
    scrollDown();
    sendController.value = TextEditingValue(
      text: sendController.value.text,
      selection: const TextSelection.collapsed(offset: 0),
    );
    inputFocus.unfocus();
    final textEvent = await _triggerTagGreetingMessage();
    isSendingNotifier.value = true;
    _createRoom(
      onRoomCreatedSuccess: (room) {
        room.sendTextEvent(
          textEvent,
        );
      },
      onRoomCreatedFailed: onCreateRoomFailed,
    );
  }

  Future<void> _createRoom({
    OnRoomCreatedSuccess onRoomCreatedSuccess,
    OnRoomCreatedFailed onRoomCreatedFailed,
  }) async {
    _createRoomSubscription = createDirectChatInteractor
        .execute(
      contactMxId: presentationContact.matrixId!,
      client: Matrix.of(context).client,
      enableEncryption: false,
    )
        .listen((event) {
      event.fold((failure) {
        onRoomCreatedFailed?.call();
        Logs().d("_createRoom: $failure");
        isSendingNotifier.value = false;
      }, (success) async {
        if (success is CreateDirectChatSuccess) {
          final room = Matrix.of(context).client.getRoomById(success.roomId);
          if (room != null) {
            onRoomCreatedSuccess?.call(room);
            context.go(
              '/rooms/${room.id}/',
              extra: ChatRouterInputArgument(
                type: ChatRouterInputArgumentType.draft,
                data: _userProfile.value?.displayName ??
                    presentationContact.displayName ??
                    room.name,
              ),
            );
          }
        }
      });
    });
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

  void typeEmoji(String emoji) {
    if (emoji.isEmpty) return;
    final emojiId = Matrix.of(context).emojiData.getIdByEmoji(emoji);

    if (emojiId.isNotEmpty) {
      storeRecentReactionsInteractor.execute(emojiId: emojiId);
    }
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
      onPickerTypeTap: (action) => onPickerTypeClick(
        type: action,
        context: context,
      ),
      onSendTap: () => sendMedia(imagePickerController),
      onCameraPicked: (_) => sendMedia(imagePickerController),
      typeAheadKey: _draftChatMediaPickerTypeAheadKey,
    );
  }

  void sendFileOnWebAction(
    BuildContext context, {
    Room? room,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;

    final matrixFilesList = await Future.wait(
      result.xFiles.map(
        (file) async {
          try {
            return (await file.toMatrixFileOnWeb()).detectFileType;
          } catch (e) {
            return null;
          }
        },
      ),
    );

    _handleSendFileOnWeb(context, matrixFilesList.nonNulls.toList());
  }

  Future<void> _handleSendFileOnWeb(
    BuildContext context,
    List<MatrixFile> matrixFilesList,
  ) async {
    if (matrixFilesList.isEmpty) {
      TwakeSnackBar.show(
        context,
        L10n.of(context)!.failedToSendFiles,
      );
      return;
    }

    final pendingText = sendController.text;
    sendController.clear();

    final dialogResult = await sendImagesWithCaption(
      context: context,
      matrixFiles: matrixFilesList,
      pendingText: pendingText,
    );

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
        isSendingNotifier.value = true;
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
        _userProfile.value?.displayName ??
            presentationContact.displayName ??
            '',
      ),
    );
    onInputBarChanged(sendController.text);
  }

  Future<void> _getProfile() async {
    try {
      final profile = await Matrix.of(context).client.getProfileFromUserId(
            presentationContact.matrixId!,
            getFromRooms: false,
          );
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
