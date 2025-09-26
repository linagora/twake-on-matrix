import 'package:fluffychat/pages/chat/chat_input_row_style.dart';
import 'package:fluffychat/presentation/mixins/audio_mixin.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ChatInputRowSendBtn extends StatelessWidget {
  final ValueListenable<String> inputText;
  final ValueNotifier<bool>? sendingNotifier;
  final void Function() onTap;
  final void Function()? onTapRecorderWeb;
  final void Function()? onFinishRecorderWeb;
  final void Function()? onDeleteRecorderWeb;
  final ValueNotifier<AudioRecordState> audioRecordStateNotifier;

  const ChatInputRowSendBtn({
    super.key,
    required this.inputText,
    required this.onTap,
    this.sendingNotifier,
    this.onTapRecorderWeb,
    required this.audioRecordStateNotifier,
    this.onFinishRecorderWeb,
    this.onDeleteRecorderWeb,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: inputText,
      builder: (context, textInput, child) {
        if (PlatformInfos.isWeb && textInput.isEmpty) {
          return ValueListenableBuilder(
            valueListenable: audioRecordStateNotifier,
            builder: (context, audioState, _) {
              return Row(
                children: [
                  if (audioState == AudioRecordState.recording) ...[
                    Padding(
                      padding: ChatInputRowStyle.sendIconPadding,
                      child: TwakeIconButton(
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        size: ChatInputRowStyle.sendIconBtnSize,
                        imagePath: ImagePaths.icDeleteRecorderWeb,
                        onTap: () => onDeleteRecorderWeb?.call(),
                        paddingAll: 0,
                      ),
                    ),
                    Padding(
                      padding: ChatInputRowStyle.sendIconPadding,
                      child: TwakeIconButton(
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        size: ChatInputRowStyle.sendIconBtnSize,
                        imagePath: ImagePaths.icSend,
                        onTap: () => onFinishRecorderWeb?.call(),
                        paddingAll: 0,
                      ),
                    ),
                  ] else
                    Padding(
                      padding: ChatInputRowStyle.sendIconPadding,
                      child: TwakeIconButton(
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        size: ChatInputRowStyle.sendIconBtnSize,
                        imagePath: ImagePaths.icRecorder,
                        onTap: () => onTapRecorderWeb?.call(),
                        paddingAll: 0,
                      ),
                    ),
                ],
              );
            },
          );
        }

        if (textInput.isNotEmpty) {
          return child!;
        }

        return const SizedBox();
      },
      child: ValueListenableBuilder(
        valueListenable: sendingNotifier ?? ValueNotifier(false),
        builder: (context, isSending, child) {
          if (isSending) {
            return child!;
          }
          return Padding(
            padding: ChatInputRowStyle.sendIconPadding,
            child: TwakeIconButton(
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              size: ChatInputRowStyle.sendIconBtnSize,
              onTap: onTap,
              tooltip: L10n.of(context)!.send,
              imagePath: ImagePaths.icSend,
              paddingAll: 0,
            ),
          );
        },
        child: const Padding(
          padding: ChatInputRowStyle.sendIconPadding,
          child: Center(
            child: SizedBox(
              width: ChatInputRowStyle.sendIconBtnSize,
              height: ChatInputRowStyle.sendIconBtnSize,
              child: CupertinoActivityIndicator(),
            ),
          ),
        ),
      ),
    );
  }
}
