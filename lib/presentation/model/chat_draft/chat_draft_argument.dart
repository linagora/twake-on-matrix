import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:fluffychat/config/go_routes/router_arguments.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:flutter/material.dart';

typedef OnTapDirectDraftChat = Function();
typedef OnInputBarChanged = Function(String);
typedef OnEmojiPickerAction = Function();
typedef OnPressedAddMore = Function();
typedef OnInputBarSubmitted = Function(String);
typedef OnSendText = Function();
typedef OnEmojiBottomSheetSelected = Function(Category?, Emoji);
typedef OnEmojiPickerBackspace = Function();

class ChatDraftArgument extends RouterArguments {
  final bool? showEmojiPicker;
  final EmojiPickerType emojiPickerType;
  final String? matrixId;
  final String? displayName;
  final FocusNode? inputFocus;
  final TextEditingController? textEditingController;
  final String inputText;
  final OnTapDirectDraftChat? onTapDirectDraftChat;
  final OnInputBarChanged? onInputBarChanged;
  final OnEmojiPickerAction? emojiPickerAction;
  final OnPressedAddMore? onPressedAddMore;
  final OnInputBarSubmitted? onInputBarSubmitted;
  final OnSendText? sendText;
  final OnEmojiBottomSheetSelected? onEmojiBottomSheetSelected;
  final OnEmojiPickerBackspace? emojiPickerBackspace;

  ChatDraftArgument({
    required this.inputText,
    required this.emojiPickerType,
    this.showEmojiPicker,
    this.onPressedAddMore,
    this.onInputBarSubmitted,
    this.matrixId,
    this.displayName,
    this.onTapDirectDraftChat,
    this.inputFocus,
    this.textEditingController,
    this.onInputBarChanged,
    this.emojiPickerAction,
    this.sendText,
    this.onEmojiBottomSheetSelected,
    this.emojiPickerBackspace,
  });

  @override
  List<Object?> get props => [
        showEmojiPicker,
        emojiPickerType,
        onPressedAddMore,
        onInputBarSubmitted,
        matrixId,
        displayName,
        onTapDirectDraftChat,
        inputFocus,
        textEditingController,
        onInputBarChanged,
        emojiPickerAction,
        inputText,
        sendText,
        onEmojiBottomSheetSelected,
        emojiPickerBackspace,
      ];
}
