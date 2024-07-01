import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/direct_chat/create_direct_chat_success.dart';
import 'package:fluffychat/domain/model/extensions/platform_file/platform_file_extension.dart';
import 'package:fluffychat/domain/usecase/create_direct_chat_interactor.dart';
import 'package:fluffychat/domain/usecase/send_file_on_web_interactor.dart';
import 'package:fluffychat/domain/usecase/send_media_on_web_with_caption_interactor.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_view.dart';
import 'package:fluffychat/presentation/enum/chat/right_column_type_enum.dart';
import 'package:fluffychat/presentation/mixins/common_media_picker_mixin.dart';
import 'package:fluffychat/presentation/mixins/media_picker_mixin.dart';
import 'package:fluffychat/presentation/mixins/send_files_mixin.dart';
import 'package:fluffychat/presentation/model/chat/chat_router_input_argument.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:fluffychat/utils/network_connection_service.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/mixins/drag_drog_file_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
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
typedef OnEmojiAction = void Function();
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
        DragDrogFileMixin {
  final createDirectChatInteractor = getIt.get<CreateDirectChatInteractor>();

  final NetworkConnectionService networkConnectionService =
      getIt.get<NetworkConnectionService>();

  final AutoScrollController scrollController = AutoScrollController();
  final AutoScrollController forwardListController = AutoScrollController();

  final FocusSuggestionController focusSuggestionController =
      FocusSuggestionController();

  StreamSubscription? _createRoomSubscription;

  final ValueKey draftChatComposerTypeAheadKey =
      const ValueKey('draftChatComposerTypeAheadKey');

  final ValueKey _draftChatMediaPickerTypeAheadKey =
      const ValueKey('draftChatMediaPickerTypeAheadKey');

  FocusNode inputFocus = FocusNode();
  FocusNode keyboardFocus = FocusNode();

  bool showScrollDownButton = false;

  ValueNotifier<String> inputText = ValueNotifier('');

  ValueNotifier<bool> showEmojiPickerNotifier = ValueNotifier(false);

  final ValueNotifier<Profile?> _userProfile = ValueNotifier(null);

  EmojiPickerType emojiPickerType = EmojiPickerType.keyboard;

  final isSendingNotifier = ValueNotifier(false);

  PresentationContact? get presentationContact => widget.contact;

  final KeyboardVisibilityController keyboardVisibilityController =
      KeyboardVisibilityController();

  final sendMediaWithCaptionInteractor =
      getIt.get<SendMediaOnWebWithCaptionInteractor>();

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

  @override
  Future<void> sendMedia(
    ImagePickerGridController imagePickerController, {
    String? caption,
    Room? room,
  }) {
    return _createRoom(
      onRoomCreatedSuccess: (newRoom) {
        super.sendMedia(imagePickerController, room: newRoom);
      },
    );
  }

  void handleDragDone(DropDoneDetails details) async {
    return _createRoom(
      onRoomCreatedSuccess: (newRoom) async {
        final matrixFiles = await super.onDragDone(details);
        sendImagesWithCaption(
          room: newRoom,
          context: context,
          matrixFiles: matrixFiles,
        );
      },
    );
  }

  @override
  void initState() {
    scrollController.addListener(_updateScrollController);
    keyboardVisibilityController.onChange.listen(_keyboardListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getProfile();
    });
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    sendController.dispose();
    forwardListController.dispose();
    _createRoomSubscription?.cancel();
    focusSuggestionController.dispose();
    inputText.dispose();
    showEmojiPickerNotifier.dispose();
    _userProfile.dispose();
    super.dispose();
  }

  TextEditingController sendController = TextEditingController();

  void setActiveClient(Client c) => setState(() {
        Matrix.of(context).setActiveClient(c);
      });

  Future<String> _triggerTagGreetingMessage() async {
    if (_userProfile.value == null) {
      return sendController.value.text;
    } else {
      final displayName = _userProfile.value?.displayName;
      if (sendController.value.text.contains(displayName ?? '') == true) {
        return sendController.value.text.replaceAll(
          "${displayName ?? ''}!",
          presentationContact?.matrixId ?? '',
        );
      } else {
        return sendController.value.text;
      }
    }
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
      contactMxId: presentationContact!.matrixId!,
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
                    presentationContact?.displayName ??
                    room.name,
              ),
            );
          }
        }
      });
    });
  }

  void onKeyboardAction() {
    showEmojiPickerNotifier.value = false;
    inputFocus.requestFocus();
  }

  void onEmojiAction() {
    emojiPickerType = EmojiPickerType.keyboard;
    showEmojiPickerNotifier.value = true;
    if (PlatformInfos.isMobile) {
      hideKeyboardChatScreen();
    } else {
      inputFocus.requestFocus();
    }
  }

  void scrollDown() {
    if (scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
  }

  void onEmojiBottomSheetSelected(Emoji? emoji) {
    typeEmoji(emoji);
    onInputBarChanged(sendController.text);
    if (PlatformInfos.isWeb) {
      inputFocus.requestFocus();
    }
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

    showMediaPickerBottomSheetAction(
      context: context,
      imagePickerGridController: imagePickerController,
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
    final sendFileOnWebInteractor = getIt.get<SendFileOnWebInteractor>();
    final result = await FilePicker.platform.pickFiles(
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final matrixFilesList = result.files
        .map(
          (file) => file.toMatrixFileOnWeb().detectFileType,
        )
        .toList();

    await sendImagesWithCaption(
      context: context,
      matrixFiles: [matrixFilesList.first],
    );
    isSendingNotifier.value = true;
    _createRoom(
      onRoomCreatedSuccess: (newRoom) {
        if (matrixFilesList.first is MatrixImageFile) {
          sendMediaWithCaptionInteractor.execute(
            room: newRoom,
            media: matrixFilesList.first,
          );
        } else {
          sendFileOnWebInteractor.execute(
            room: newRoom,
            files: matrixFilesList,
          );
        }
      },
    );
  }

  void onPushDetails() {
    widget.onChangeRightColumnType?.call(RightColumnType.profileInfo);
  }

  Future<void> handleDraftAction(BuildContext context) async {
    inputFocus.requestFocus();
    sendController.value = TextEditingValue(
      text: L10n.of(context)!.draftChatHookPhrase(
        _userProfile.value?.displayName ??
            presentationContact?.displayName ??
            '',
      ),
    );
    onInputBarChanged(sendController.text);
  }

  Future<void> _getProfile() async {
    try {
      final profile = await Matrix.of(context).client.getProfileFromUserId(
            presentationContact!.matrixId!,
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

  void _keyboardListener(bool isKeyboardVisible) {
    if (isKeyboardVisible && showEmojiPickerNotifier.value == true) {
      showEmojiPickerNotifier.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraftChatView(controller: this);
  }
}
