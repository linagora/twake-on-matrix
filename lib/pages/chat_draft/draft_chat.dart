import 'dart:async';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/direct_chat/create_direct_chat_success.dart';
import 'package:fluffychat/domain/usecase/create_direct_chat_interactor.dart';
import 'package:fluffychat/domain/usecase/send_file_on_web_interactor.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_view.dart';
import 'package:fluffychat/presentation/mixins/common_media_picker_mixin.dart';
import 'package:fluffychat/presentation/mixins/media_picker_mixin.dart';
import 'package:fluffychat/presentation/mixins/send_files_mixin.dart';
import 'package:fluffychat/presentation/model/chat/chat_router_input_argument.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/presentation/model/presentation_contact_constant.dart';
import 'package:fluffychat/utils/network_connection_service.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/images_picker/asset_counter.dart';
import 'package:linagora_design_flutter/images_picker/images_picker.dart'
    hide ImagePicker;
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

typedef OnRoomCreatedSuccess = FutureOr<void> Function(Room room)?;
typedef OnRoomCreatedFailed = FutureOr<void> Function()?;

class DraftChat extends StatefulWidget {
  final GoRouterState state;

  const DraftChat({super.key, required this.state});

  @override
  State<StatefulWidget> createState() => DraftChatController();
}

class DraftChatController extends State<DraftChat>
    with CommonMediaPickerMixin, MediaPickerMixin, SendFilesMixin {
  final createDirectChatInteractor = getIt.get<CreateDirectChatInteractor>();

  PresentationContact? presentationContact;

  final NetworkConnectionService networkConnectionService =
      getIt.get<NetworkConnectionService>();

  final AutoScrollController scrollController = AutoScrollController();
  final AutoScrollController forwardListController = AutoScrollController();

  FocusNode inputFocus = FocusNode();

  bool showScrollDownButton = false;

  String inputText = '';

  bool showEmojiPicker = false;

  EmojiPickerType emojiPickerType = EmojiPickerType.keyboard;

  final isSendingNotifier = ValueNotifier(false);

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
  Future<void> sendImages(
    ImagePickerGridController imagePickerController, {
    Room? room,
  }) {
    return _createRoom(
      onRoomCreatedSuccess: (newRoom) {
        super.sendImages(imagePickerController, room: newRoom);
      },
    );
  }

  @override
  void initState() {
    final extra = widget.state.extra as Map<String, String>;
    if (extra.isNotEmpty) {
      presentationContact = PresentationContact(
        matrixId: extra[PresentationContactConstant.receiverId],
        email: extra[PresentationContactConstant.email],
        displayName: extra[PresentationContactConstant.displayName],
      );
    } else {
      presentationContact =
          const PresentationContact().presentationContactEmpty;
    }

    scrollController.addListener(_updateScrollController);
    inputFocus.addListener(_inputFocusListener);
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    sendController.dispose();
    forwardListController.dispose();
    inputFocus.removeListener(_inputFocusListener);
    super.dispose();
  }

  TextEditingController sendController = TextEditingController();

  void setActiveClient(Client c) => setState(() {
        Matrix.of(context).setActiveClient(c);
      });

  Future<void> sendText({
    OnRoomCreatedSuccess onRoomCreatedSuccess,
    OnRoomCreatedFailed onCreateRoomFailed,
  }) async {
    scrollDown();
    sendController.value = TextEditingValue(
      text: sendController.value.text,
      selection: const TextSelection.collapsed(offset: 0),
    );
    inputFocus.unfocus();
    isSendingNotifier.value = true;
    _createRoom(
      onRoomCreatedSuccess: (room) {
        onRoomCreatedSuccess?.call(room);
        room.sendTextEvent(
          sendController.text,
        );
      },
      onRoomCreatedFailed: onCreateRoomFailed,
    );
  }

  Future<void> _createRoom({
    OnRoomCreatedSuccess onRoomCreatedSuccess,
    OnRoomCreatedFailed onRoomCreatedFailed,
  }) async {
    createDirectChatInteractor
        .execute(
      contactMxId: presentationContact!.matrixId!,
      client: Matrix.of(context).client,
      enableEncryption: true,
    )
        .listen((event) {
      event.fold((failure) {
        onRoomCreatedFailed?.call();
        Logs().d("_createRoom: $failure");
        isSendingNotifier.value = false;
      }, (success) {
        if (success is CreateDirectChatSuccess) {
          final room = Matrix.of(context).client.getRoomById(success.roomId);
          if (room != null) {
            onRoomCreatedSuccess?.call(room);
            context.go(
              '/rooms/${room.id}/',
              extra: ChatRouterInputArgument(
                type: ChatRouterInputArgumentType.draft,
                data: presentationContact?.displayName ??
                    presentationContact?.matrixId,
              ),
            );
          }
        }
      });
    });
  }

  void emojiPickerAction() {
    if (showEmojiPicker) {
      inputFocus.requestFocus();
    } else {
      inputFocus.unfocus();
    }
    emojiPickerType = EmojiPickerType.keyboard;
    setState(() => showEmojiPicker = !showEmojiPicker);
  }

  void _inputFocusListener() {
    if (showEmojiPicker && inputFocus.hasFocus) {
      emojiPickerType = EmojiPickerType.keyboard;
      if (mounted) {
        setState(() => showEmojiPicker = false);
      }
    }
  }

  void scrollDown() {
    if (scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
  }

  void onEmojiBottomSheetSelected(_, Emoji? emoji) {
    typeEmoji(emoji);
    onInputBarChanged(sendController.text);
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
  }

  void onInputBarSubmitted(_) {
    sendText(
      onCreateRoomFailed: () {
        Fluttertoast.showToast(msg: 'Create room failed');
        FocusScope.of(context).requestFocus(inputFocus);
      },
    );
  }

  void onInputBarChanged(String text) {
    setState(() => inputText = text);
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
      onSendTap: () => sendImages(imagePickerController),
      onCameraPicked: (_) => sendImages(imagePickerController),
    );
  }

  @override
  void sendFileOnWebAction(
    BuildContext context, {
    Room? room,
  }) async {
    final sendFileOnWebInteractor = getIt.get<SendFileOnWebInteractor>();
    final result = await FilePicker.platform.pickFiles(
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    _createRoom(
      onRoomCreatedSuccess: (newRoom) {
        sendFileOnWebInteractor.execute(
          room: newRoom,
          filePickerResult: result,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraftChatView(controller: this);
  }
}
