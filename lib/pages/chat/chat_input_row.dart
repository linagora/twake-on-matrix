import 'package:fluffychat/pages/chat/animate_pause_button.dart';
import 'package:fluffychat/pages/chat/chat_input_row_mobile.dart';
import 'package:fluffychat/pages/chat/chat_input_row_send_btn.dart';
import 'package:fluffychat/pages/chat/chat_input_row_style.dart';
import 'package:fluffychat/pages/chat/chat_input_row_web.dart';
import 'package:fluffychat/pages/chat/reply_display.dart';
import 'package:fluffychat/presentation/mixins/audio_mixin.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/android_utils.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/int_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:social_media_recorder/audio_encoder_type.dart';
import 'package:social_media_recorder/screen/social_media_recorder.dart';

import 'chat.dart';
import 'input_bar/input_bar.dart';

class ChatInputRow extends StatelessWidget {
  final ChatController controller;

  const ChatInputRow(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        final child = Stack(
          alignment: Alignment.centerRight,
          children: [
            Padding(
              padding: _paddingInputRow(
                context: context,
                isKeyboardVisible: isKeyboardVisible,
              ),
              child: Row(
                crossAxisAlignment:
                    ChatInputRowStyle.responsiveUtils.isMobile(context)
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: controller.selectMode
                    ? [ActionSelectModeWidget(controller: controller)]
                    : <Widget>[
                        if (ChatInputRowStyle.responsiveUtils.isMobile(context))
                          ValueListenableBuilder(
                            valueListenable:
                                controller.audioRecordStateNotifier,
                            builder: (context, audioState, _) {
                              if (PlatformInfos.isWeb &&
                                  audioState != AudioRecordState.initial) {
                                return const SizedBox.shrink();
                              }

                              return SizedBox(
                                height: ChatInputRowStyle.chatInputRowHeight,
                                child: TwakeIconButton(
                                  size:
                                      ChatInputRowStyle.chatInputRowMoreBtnSize,
                                  tooltip: L10n.of(context)!.more,
                                  icon: Icons.add_circle_outline,
                                  onTap: () =>
                                      controller.onSendFileClick(context),
                                ),
                              );
                            },
                          ),
                        if (controller.matrix!.isMultiAccount &&
                            controller.matrix!.hasComplexBundles &&
                            controller.matrix!.currentBundle!.length > 1)
                          Container(
                            height: ChatInputRowStyle.chatInputRowHeight,
                            alignment: Alignment.center,
                            child: ChatAccountPicker(controller),
                          ),
                        ValueListenableBuilder(
                          valueListenable: controller.audioRecordStateNotifier,
                          builder: (context, audioState, _) {
                            if (PlatformInfos.isWeb &&
                                audioState != AudioRecordState.initial) {
                              return Expanded(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight:
                                        ChatInputRowStyle.chatInputRowHeight,
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: ChatInputRowStyle
                                        .chatInputRowPaddingMobile,
                                    decoration: BoxDecoration(
                                      borderRadius: ChatInputRowStyle
                                          .chatInputRowBorderRadius,
                                      color: LinagoraSysColors.material()
                                          .onPrimary,
                                      border: Border.all(
                                        color: LinagoraRefColors.material()
                                            .tertiary,
                                        width: 1,
                                      ),
                                    ),
                                    child: _counterAudioWeb(context: context),
                                  ),
                                ),
                              );
                            }
                            return Expanded(
                              child:
                                  ChatInputRowStyle.responsiveUtils.isMobile(
                                    context,
                                  )
                                  ? _buildMobileInputRow(context)
                                  : _buildWebInputRow(context),
                            );
                          },
                        ),
                        ChatInputRowSendBtn(
                          inputText: controller.inputText,
                          onTap: controller.onInputBarSubmitted,
                          onTapRecorderWeb: () =>
                              controller.onTapRecorderWeb(context: context),
                          audioRecordStateNotifier:
                              controller.audioRecordStateNotifier,
                          onDeleteRecorderWeb: controller.stopRecordWeb,
                          onFinishRecorderWeb: controller.sendVoiceMessageWeb,
                        ),
                      ],
              ),
            ),
            if (PlatformInfos.isMobile && controller.selectMode == false)
              ValueListenableBuilder(
                valueListenable: controller.inputText,
                builder: (context, text, _) {
                  return ValueListenableBuilder(
                    valueListenable: controller.replyEventNotifier,
                    builder: (context, reply, _) {
                      final view = View.maybeOf(context);
                      final bottomInset =
                          (view?.viewInsets.bottom ?? 0) /
                          (view?.devicePixelRatio ?? 0);
                      return Offstage(
                        offstage: text.isNotEmpty || reply != null,
                        child: Padding(
                          padding: _paddingAudioRow(
                            context: context,
                            isKeyboardVisible: isKeyboardVisible,
                          ),
                          child: SocialMediaRecorder(
                            radius: BorderRadius.circular(24),
                            pauseBottomPositioned:
                                102 + (isKeyboardVisible ? bottomInset : 16),
                            pauseRightPositioned: 16,
                            resumeDecoration: BoxDecoration(
                              color: LinagoraSysColors.material().surface,
                            ),
                            soundRecorderWhenLockedDecoration: BoxDecoration(
                              borderRadius:
                                  ChatInputRowStyle.chatInputRowBorderRadius,
                              color: LinagoraSysColors.material().onPrimary,
                              border: Border.all(
                                color: LinagoraRefColors.material().tertiary,
                                width: 1,
                              ),
                            ),
                            decoration: BoxDecoration(
                              borderRadius:
                                  ChatInputRowStyle.chatInputRowBorderRadius,
                              color: LinagoraSysColors.material().onPrimary,
                              border: Border.all(
                                color: LinagoraRefColors.material().tertiary,
                                width: 1,
                              ),
                            ),
                            microphoneRequestPermission:
                                controller.onLongPressAudioRecordInMobile,
                            startRecording: () {
                              Logs().d('ChatInputRowMobile:: startRecording');
                              controller.startRecording.call();
                            },
                            stopRecording: (_) {
                              Logs().d('ChatInputRowMobile:: stopRecording');
                              if (controller.audioRecordStateNotifier.value !=
                                  AudioRecordState.recording) {
                                return;
                              }
                              if (controller.sendController.text.isNotEmpty) {
                                controller.sendController.clear();
                              }
                              controller.stopRecording.call();
                            },
                            deleteRecording: () {
                              Logs().d('ChatInputRowMobile:: deleteRecording');
                              if (controller.sendController.text.isNotEmpty) {
                                controller.sendController.clear();
                              }
                              controller.stopRecording.call();
                            },
                            pauseRecording: () {
                              Logs().d('ChatInputRowMobile:: pauseRecording');
                              controller.pauseRecording.call();
                            },
                            sendRequestFunction: (soundFile, time, waveFrom) async {
                              Logs().d(
                                'ChatInputRowMobile:: sendRequestFunction $soundFile',
                              );
                              controller.stopRecording.call();

                              try {
                                final file = TwakeAudioFile(
                                  name: soundFile.path,
                                  duration: time.inMilliseconds,
                                  bytes: await soundFile.readAsBytes(),
                                );
                                controller.sendVoiceMessageAction(
                                  audioFile: file,
                                  path: soundFile.path,
                                  time: time,
                                  waveform: waveFrom,
                                );
                              } catch (error, stackTrace) {
                                Logs().e(
                                  'ChatInputRowMobile:: sendRequestFunction:',
                                  error,
                                  stackTrace,
                                );
                              }
                            },
                            encode: AudioEncoderType.AAC,
                            fullRecordPackageHeight: 50,
                            initRecordPackageWidth: 50,
                            cancelTextBackGroundColor: Colors.transparent,
                            cancelText: L10n.of(context)!.cancel,
                            cancelTextStyle: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: LinagoraSysColors.material().primary,
                                ),
                            slideToCancelText: L10n.of(context)!.slideToCancel,
                            slideToCancelTextStyle: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      LinagoraRefColors.material().neutral[30],
                                ),
                            counterTextStyle: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      LinagoraRefColors.material().neutral[50],
                                ),
                            slideToCancelPadding: const EdgeInsets.only(
                              right: 24,
                            ),
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
                            pauseSplashColor: LinagoraSysColors.material()
                                .primary
                                .withOpacity(0.5),
                            pauseHighlightColor: LinagoraSysColors.material()
                                .primary
                                .withOpacity(0.2),
                            pauseWidget: const AnimatedPauseButton(),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        );

        if (AndroidUtils.isNavigationButtonsEnabled(
          systemGestureInsets: MediaQuery.systemGestureInsetsOf(context),
        )) {
          return SafeArea(child: child);
        }

        return child;
      },
    );
  }

  Widget _counterAudioWeb({required BuildContext context}) {
    return ValueListenableBuilder(
      valueListenable: controller.recordDurationWebNotifier,
      builder: (context, duration, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 8),
            AnimatedOpacity(
              duration: const Duration(seconds: 1),
              opacity: (duration % 60) % 2 == 0 ? 1 : 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LinagoraSysColors.material().error,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  (duration ~/ 60).formatNumberAudioDuration(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LinagoraRefColors.material().neutral[50],
                  ),
                ),
                Text(
                  " : ",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LinagoraRefColors.material().neutral[50],
                  ),
                ),
                Text(
                  (duration % 60).formatNumberAudioDuration(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LinagoraRefColors.material().neutral[50],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  EdgeInsetsGeometry _paddingInputRow({
    required BuildContext context,
    required bool isKeyboardVisible,
  }) {
    if (!ChatInputRowStyle.responsiveUtils.isMobile(context)) {
      return EdgeInsets.zero;
    }

    if (isKeyboardVisible ||
        AndroidUtils.isNavigationButtonsEnabled(
          systemGestureInsets: MediaQuery.systemGestureInsetsOf(context),
        )) {
      return EdgeInsets.zero;
    }
    return const EdgeInsets.only(bottom: 16);
  }

  EdgeInsetsGeometry _paddingAudioRow({
    required BuildContext context,
    required bool isKeyboardVisible,
  }) {
    if (!ChatInputRowStyle.responsiveUtils.isMobile(context)) {
      return EdgeInsets.zero;
    }

    if (isKeyboardVisible ||
        AndroidUtils.isNavigationButtonsEnabled(
          systemGestureInsets: MediaQuery.systemGestureInsetsOf(context),
        )) {
      return EdgeInsets.zero;
    }
    return const EdgeInsets.only(bottom: 16);
  }

  ChatInputRowMobile _buildMobileInputRow(BuildContext context) {
    return ChatInputRowMobile(
      inputBar: ValueListenableBuilder(
        valueListenable: controller.showEmojiPickerNotifier,
        builder: (context, value, _) {
          return Column(
            children: [
              ReplyDisplay(controller),
              Offstage(offstage: value, child: _buildInputBar(context)),
            ],
          );
        },
      ),
    );
  }

  ChatInputRowWeb _buildWebInputRow(BuildContext context) {
    return ChatInputRowWeb(
      editEventNotifier: controller.editEventNotifier,
      onCloseEditAction: controller.cancelEditEventAction,
      inputBar: Column(
        children: [ReplyDisplay(controller), _buildInputBar(context)],
      ),
      onTapMoreBtn: () => controller.onSendFileClick(context),
      onEmojiAction: controller.onEmojiAction,
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return InputBar(
      typeAheadKey: controller.chatComposerTypeAheadKey,
      rawKeyboardFocusNode: controller.rawKeyboardListenerFocusNode,
      room: controller.room!,
      minLines: 1,
      maxLines: 8,
      autofocus: !PlatformInfos.isMobile,
      keyboardType: TextInputType.multiline,
      textInputAction: null,
      onSubmitted: (_) => controller.onInputBarSubmitted(),
      suggestionsController: controller.suggestionsController,
      typeAheadFocusNode: controller.inputFocus,
      controller: controller.sendController,
      focusSuggestionController: controller.focusSuggestionController,
      suggestionScrollController: controller.suggestionScrollController,
      showEmojiPickerNotifier: controller.showEmojiPickerNotifier,
      decoration: InputDecoration(
        contentPadding: ChatInputRowStyle.contentPadding(context),
        hintText: L10n.of(context)!.message,
        isDense: true,
        hintMaxLines: 1,
        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: controller.responsive.isMobile(context)
              ? LinagoraRefColors.material().tertiary[50]
              : LinagoraRefColors.material().tertiary[30],
          fontFamily: 'Inter',
        ),
      ),
      onChanged: controller.onInputBarChanged,
    );
  }
}

class ActionSelectModeWidget extends StatelessWidget {
  final ChatController controller;

  const ActionSelectModeWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (controller.selectedEvents.first
              .getDisplayEventWithoutEditEvent(controller.timeline!)
              .status
              .isSent)
            SizedBox(
              height: ChatInputRowStyle.chatInputRowHeight,
              child: TextButton(
                onPressed: controller.forwardEventsAction,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.keyboard_arrow_left_outlined),
                    Text(L10n.of(context)!.forward),
                  ],
                ),
              ),
            ),
          if (controller.selectedEvents.length == 1) ...[
            if (controller.selectedEvents.first
                    .getDisplayEventWithoutEditEvent(controller.timeline!)
                    .status
                    .isSent &&
                controller
                    .selectedEvents
                    .first
                    .room
                    .canSendDefaultMessages) ...[
              SizedBox(
                height: ChatInputRowStyle.chatInputRowHeight,
                child: TextButton(
                  onPressed: controller.replyAction,
                  child: Row(
                    children: <Widget>[
                      Text(L10n.of(context)!.reply),
                      const Icon(Icons.keyboard_arrow_right),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const SizedBox.shrink(),
            ],
          ] else if (controller.selectedEvents.first
              .getDisplayEventWithoutEditEvent(controller.timeline!)
              .status
              .isError) ...[
            SizedBox(
              height: ChatInputRowStyle.chatInputRowHeight,
              child: TextButton(
                onPressed: controller.sendAgainAction,
                child: Row(
                  children: <Widget>[
                    Text(L10n.of(context)!.tryToSendAgain),
                    const SizedBox(width: 4),
                    SvgPicture.asset(ImagePaths.icSend),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox.shrink(),
          ],
        ],
      ),
    );
  }
}

class ChatAccountPicker extends StatelessWidget {
  final ChatController controller;

  const ChatAccountPicker(this.controller, {super.key});

  void _popupMenuButtonSelected(String mxid) {
    final client = controller.matrix!.currentBundle!.firstWhere(
      (cl) => cl!.userID == mxid,
      orElse: () => null,
    );
    if (client == null) {
      Logs().w('Attempted to switch to a non-existing client $mxid');
      return;
    }
    controller.setSendingClient(client);
  }

  @override
  Widget build(BuildContext context) {
    controller.matrix ??= Matrix.of(context);
    final clients = controller.currentRoomBundle;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder<Profile>(
        future: controller.sendingClient!.fetchOwnProfile(),
        builder: (context, snapshot) => PopupMenuButton<String>(
          onSelected: _popupMenuButtonSelected,
          itemBuilder: (BuildContext context) => clients
              .map(
                (client) => PopupMenuItem<String>(
                  value: client!.userID,
                  child: FutureBuilder<Profile>(
                    future: client.fetchOwnProfile(),
                    builder: (context, snapshot) => ListTile(
                      leading: Avatar(
                        mxContent: snapshot.data?.avatarUrl,
                        name:
                            snapshot.data?.displayName ??
                            client.userID!.localpart,
                        size: 20,
                      ),
                      title: Text(snapshot.data?.displayName ?? client.userID!),
                      contentPadding: const EdgeInsets.all(0),
                    ),
                  ),
                ),
              )
              .toList(),
          child: Avatar(
            mxContent: snapshot.data?.avatarUrl,
            name:
                snapshot.data?.displayName ??
                controller.matrix!.client.userID!.localpart,
            size: 20,
            fontSize: 8,
          ),
        ),
      ),
    );
  }
}
