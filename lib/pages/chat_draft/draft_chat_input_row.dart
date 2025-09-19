import 'package:fluffychat/pages/chat/chat_input_row_mobile.dart';
import 'package:fluffychat/pages/chat/chat_input_row_send_btn.dart';
import 'package:fluffychat/pages/chat/chat_input_row_style.dart';
import 'package:fluffychat/pages/chat/chat_input_row_web.dart';
import 'package:fluffychat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:fluffychat/pages/chat/input_bar/input_bar.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_input_row_style.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_view_style.dart';
import 'package:fluffychat/presentation/mixins/audio_mixin.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:social_media_recorder/audio_encoder_type.dart';
import 'package:social_media_recorder/screen/social_media_recorder.dart';

class DraftChatInputRow extends StatelessWidget {
  final OnSendFileClick onSendFileClick;
  final ValueNotifier<String> inputText;
  final OnInputBarSubmitted onInputBarSubmitted;
  final ValueNotifier<bool> isSendingNotifier;
  final OnEmojiAction onEmojiAction;
  final ValueKey typeAheadKey;
  final OnInputBarChanged onInputBarChanged;
  final FocusNode? typeAheadFocusNode;
  final TextEditingController? textEditingController;
  final FocusSuggestionController focusSuggestionController;
  final void Function()? onLongPressAudioRecord;
  final ValueNotifier<AudioRecordState> audioRecordStateNotifier;
  final Function()? startRecording;
  final Function()? stopRecording;
  final void Function(TwakeAudioFile, Duration, List<int>)?
      sendVoiceMessageAction;

  const DraftChatInputRow({
    super.key,
    required this.onSendFileClick,
    required this.inputText,
    required this.onInputBarSubmitted,
    required this.isSendingNotifier,
    required this.onEmojiAction,
    required this.typeAheadKey,
    required this.onInputBarChanged,
    this.typeAheadFocusNode,
    this.textEditingController,
    required this.focusSuggestionController,
    this.onLongPressAudioRecord,
    required this.audioRecordStateNotifier,
    this.startRecording,
    this.stopRecording,
    this.sendVoiceMessageAction,
  });

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: DraftChatInputRowStyle.inputBarPadding(
                context: context,
                isKeyboardVisible: isKeyboardVisible,
              ),
              child: Row(
                crossAxisAlignment:
                    ChatInputRowStyle.responsiveUtils.isMobile(context)
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (ChatInputRowStyle.responsiveUtils.isMobile(context))
                    SizedBox(
                      height: ChatInputRowStyle.chatInputRowHeight,
                      child: TwakeIconButton(
                        size: ChatInputRowStyle.chatInputRowMoreBtnSize,
                        tooltip: L10n.of(context)!.more,
                        icon: Icons.add_circle_outline,
                        onTap: () => onSendFileClick(context),
                      ),
                    ),
                  Expanded(
                    child: ChatInputRowStyle.responsiveUtils.isMobile(context)
                        ? _buildMobileInputRow(context)
                        : _buildWebInputRow(context),
                  ),
                  ChatInputRowSendBtn(
                    inputText: inputText,
                    onTap: onInputBarSubmitted,
                    sendingNotifier: isSendingNotifier,
                  ),
                ],
              ),
            ),
            if (PlatformInfos.isMobile)
              _recoderMobileBuilder(
                context: context,
                isKeyboardVisible: isKeyboardVisible,
              ),
          ],
        );
      },
    );
  }

  Widget _recoderMobileBuilder({
    required BuildContext context,
    required bool isKeyboardVisible,
  }) {
    return ValueListenableBuilder(
      valueListenable: inputText,
      builder: (context, text, _) {
        return Offstage(
          offstage: text.isNotEmpty,
          child: Padding(
            padding: DraftChatInputRowStyle.inputBarPadding(
              context: context,
              isKeyboardVisible: isKeyboardVisible,
            ),
            child: SocialMediaRecorder(
              radius: BorderRadius.circular(24),
              soundRecorderWhenLockedDecoration: BoxDecoration(
                borderRadius: ChatInputRowStyle.chatInputRowBorderRadius,
                color: LinagoraSysColors.material().onPrimary,
                border: Border.all(
                  color: LinagoraRefColors.material().tertiary,
                  width: 1,
                ),
              ),
              decoration: BoxDecoration(
                borderRadius: ChatInputRowStyle.chatInputRowBorderRadius,
                color: LinagoraSysColors.material().onPrimary,
                border: Border.all(
                  color: LinagoraRefColors.material().tertiary,
                  width: 1,
                ),
              ),
              microphoneRequestPermission: onLongPressAudioRecord,
              startRecording: () {
                Logs().d('ChatInputRowMobile:: startRecording');
                startRecording?.call();
              },
              stopRecording: (_) {
                Logs().d('ChatInputRowMobile:: stopRecording');
                stopRecording?.call();
              },
              sendRequestFunction: (soundFile, time, waveFrom) {
                Logs().d(
                  'ChatInputRowMobile:: sendRequestFunction $soundFile',
                );
                stopRecording?.call();

                final file = TwakeAudioFile(
                  name: soundFile.path,
                  filePath: soundFile.path,
                  duration: time.inMilliseconds,
                );
                sendVoiceMessageAction?.call(file, time, waveFrom);
              },
              encode: AudioEncoderType.AAC,
              fullRecordPackageHeight: 50,
              initRecordPackageWidth: 50,
              cancelTextBackGroundColor: Colors.transparent,
              cancelText: L10n.of(context)!.cancel,
              cancelTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LinagoraSysColors.material().primary,
                  ),
              slideToCancelText: L10n.of(context)!.slideToCancel,
              slideToCancelTextStyle:
                  Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: LinagoraRefColors.material().neutral[30],
                      ),
              counterTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LinagoraRefColors.material().neutral[50],
                  ),
              slideToCancelPadding: const EdgeInsets.only(right: 24),
              recordIcon: Icon(
                Icons.keyboard_voice_outlined,
                color: LinagoraSysColors.material().tertiary,
              ),
              soundRecorderWhenLockedWidth:
                  MediaQuery.of(context).size.width - 16,
              counterPadding: const EdgeInsets.only(left: 16),
              micCounterWidget: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LinagoraSysColors.material().error,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  ChatInputRowMobile _buildMobileInputRow(BuildContext context) {
    return ChatInputRowMobile(
      inputBar: _buildInputBar(context),
    );
  }

  ChatInputRowWeb _buildWebInputRow(BuildContext context) {
    return ChatInputRowWeb(
      inputBar: _buildInputBar(context),
      onTapMoreBtn: () => onSendFileClick(context),
      onEmojiAction: onEmojiAction,
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Column(
      children: [
        InputBar(
          typeAheadKey: typeAheadKey,
          minLines: DraftChatViewStyle.minLinesInputBar,
          maxLines: DraftChatViewStyle.maxLinesInputBar,
          autofocus: !PlatformInfos.isMobile,
          keyboardType: TextInputType.multiline,
          textInputAction: null,
          onSubmitted: (_) => onInputBarSubmitted(),
          typeAheadFocusNode: typeAheadFocusNode,
          controller: textEditingController,
          decoration: DraftChatViewStyle.bottomBarInputDecoration(
            context,
          ),
          onChanged: onInputBarChanged,
          focusSuggestionController: focusSuggestionController,
          isDraftChat: true,
        ),
      ],
    );
  }
}
