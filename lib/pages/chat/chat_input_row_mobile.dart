import 'package:fluffychat/pages/chat/chat_input_row_style.dart';
import 'package:fluffychat/presentation/mixins/audio_mixin.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';
import 'package:social_media_recorder/audio_encoder_type.dart';
import 'package:social_media_recorder/screen/social_media_recorder.dart';

typedef OnTapEmojiAction = void Function();

class ChatInputRowMobile extends StatelessWidget {
  const ChatInputRowMobile({
    super.key,
    required this.inputBar,
    this.onLongPressAudioRecord,
    this.sendVoiceMessageAction,
    required this.inputTextNotifier,
    required this.audioRecordStateNotifier,
    this.startRecording,
    this.stopRecording,
  });

  final Widget inputBar;

  final void Function()? onLongPressAudioRecord;

  final ValueNotifier<String> inputTextNotifier;

  final ValueNotifier<AudioRecordState> audioRecordStateNotifier;

  final Function()? startRecording;

  final Function()? stopRecording;

  final void Function(
    MatrixAudioFile soundFile,
    Duration time,
    List<int> waveForm,
  )? sendVoiceMessageAction;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: ChatInputRowStyle.chatInputRowHeight,
      ),
      child: Container(
        alignment: Alignment.center,
        padding: ChatInputRowStyle.chatInputRowPaddingMobile,
        decoration: BoxDecoration(
          borderRadius: ChatInputRowStyle.chatInputRowBorderRadius,
          color: LinagoraSysColors.material().onPrimary,
          border: Border.all(
            color: LinagoraRefColors.material().tertiary,
            width: 1,
          ),
        ),
        child: ValueListenableBuilder(
          valueListenable: inputTextNotifier,
          builder: (context, text, _) {
            return Row(
              children: [
                ValueListenableBuilder(
                  valueListenable: audioRecordStateNotifier,
                  builder: (context, audioState, _) {
                    if (PlatformInfos.isMobile &&
                        audioState == AudioRecordState.initial) {
                      return Expanded(
                        child: inputBar,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                if (PlatformInfos.isMobile && text.isEmpty)
                  SocialMediaRecorder(
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

                      final file = MatrixAudioFile(
                        bytes: soundFile.readAsBytesSync(),
                        name: soundFile.path,
                        filePath: soundFile.path,
                        readStream: soundFile.openRead(),
                        duration: time.inMilliseconds,
                      );
                      sendVoiceMessageAction?.call(file, time, waveFrom);
                    },
                    encode: AudioEncoderType.AAC,
                    fullRecordPackageHeight: 50,
                    initRecordPackageWidth: 50,
                    cancelTextBackGroundColor: Colors.transparent,
                    cancelText: L10n.of(context)!.cancel,
                    cancelTextStyle:
                        Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: LinagoraSysColors.material().primary,
                            ),
                    slideToCancelText: L10n.of(context)!.slideToCancel,
                    slideToCancelTextStyle:
                        Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: LinagoraRefColors.material().neutral[30],
                            ),
                    counterTextStyle:
                        Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: LinagoraRefColors.material().neutral[50],
                            ),
                    slideToCancelPadding: const EdgeInsets.only(right: 24),
                    recordIcon: Icon(
                      Icons.keyboard_voice_outlined,
                      color: LinagoraSysColors.material().tertiary,
                    ),
                    soundRecorderWhenLockedWidth:
                        MediaQuery.of(context).size.width * 0.84,
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
              ],
            );
          },
        ),
      ),
    );
  }
}
