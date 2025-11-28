import 'dart:io';

import 'package:async/async.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/pages/chat/add_contact_banner.dart';
import 'package:fluffychat/pages/chat/blocked_message_view.dart';
import 'package:fluffychat/pages/chat/blocked_user_banner.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/chat_event_list.dart';
import 'package:fluffychat/pages/chat/chat_loading_view.dart';
import 'package:fluffychat/pages/chat/chat_view_body_style.dart';
import 'package:fluffychat/pages/chat/chat_view_style.dart';
import 'package:fluffychat/pages/chat/disabled_chat_input_row.dart';
import 'package:fluffychat/pages/chat/events/audio_message/audio_play_extension.dart';
import 'package:fluffychat/pages/chat/events/audio_message/audio_player_widget.dart';
import 'package:fluffychat/pages/chat/events/edit_display.dart';
import 'package:fluffychat/pages/chat/events/message/display_name_widget.dart';
import 'package:fluffychat/pages/chat/events/message_content_mixin.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_events_view.dart';
import 'package:fluffychat/pages/chat/sticky_timestamp_widget.dart';
import 'package:fluffychat/pages/chat/tombstone_display.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/add_contact/add_contact_dialog.dart';
import 'package:fluffychat/presentation/model/chat/view_event_list_ui_state.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/connection_status_header.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:opus_caf_converter_dart/opus_caf_converter_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'chat_input_row.dart';

class ChatViewBody extends StatelessWidget with MessageContentMixin {
  final ChatController controller;

  const ChatViewBody(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (details) => controller.handleDragDone(details),
      onDragEntered: controller.onDragEntered,
      onDragUpdated: controller.onDragUpdated,
      onDragExited: controller.onDragExited,
      child: Container(
        color: controller.responsive.isMobile(context)
            ? LinagoraSysColors.material().surface
            : null,
        child: Stack(
          children: <Widget>[
            if (Matrix.of(context).wallpaper != null)
              Image.file(
                Matrix.of(context).wallpaper!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
            Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (controller.room!.pinnedEventIds.isNotEmpty)
                      const SizedBox(
                        height: ChatViewStyle.pinnedMessageHintHeight,
                      ),
                    Expanded(
                      child: Container(
                        color: ChatViewBodyStyle.chatViewBackgroundColor(
                          context,
                        ),
                        child: GestureDetector(
                          onTap: controller.clearSingleSelectedEvent,
                          child: ValueListenableBuilder(
                            valueListenable:
                                controller.openingChatViewStateNotifier,
                            builder: (context, viewState, __) {
                              if (viewState is ViewEventListLoading ||
                                  controller.timeline == null) {
                                return const ChatLoadingView();
                              }

                              if (viewState is ViewEventListSuccess) {
                                return ChatEventList(
                                  controller: controller,
                                );
                              }

                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                    ),
                    if (controller.room!.canSendDefaultMessages &&
                        controller.room!.membership == Membership.join) ...[
                      Center(
                        child: Container(
                          alignment: Alignment.center,
                          child: controller.room?.isAbandonedDMRoom == true
                              ? Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        ChatViewBodyStyle.bottomSheetPadding(
                                      context,
                                    ),
                                    left: ChatViewBodyStyle.bottomSheetPadding(
                                      context,
                                    ),
                                    right: ChatViewBodyStyle.bottomSheetPadding(
                                      context,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.all(16),
                                          foregroundColor: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        ),
                                        icon: const Icon(
                                          Icons.archive_outlined,
                                        ),
                                        onPressed: () => controller.leaveChat(
                                          context,
                                          controller.room,
                                        ),
                                        label: Text(
                                          L10n.of(context)!.leave,
                                        ),
                                      ),
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.all(16),
                                        ),
                                        icon: const Icon(
                                          Icons.chat_outlined,
                                        ),
                                        onPressed: controller.recreateChat,
                                        label: Text(
                                          L10n.of(context)!.reopenChat,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _inputMessageWidget(context),
                        ),
                      ),
                    ] else ...[
                      const DisabledChatInputRow(),
                    ],
                  ],
                ),
                TombstoneDisplay(controller),
                Column(
                  children: [
                    ValueListenableBuilder(
                      valueListenable: controller.isBlockedUserNotifier,
                      builder: (context, isBlockedUser, _) {
                        if (!isBlockedUser) return const SizedBox.shrink();
                        return Column(
                          children: [
                            TwakeInkWell(
                              onTap: () async => controller.onTapUnblockUser(
                                context: context,
                                client: controller.client,
                                userID: controller.user?.id ?? '',
                                displayName: controller.user?.displayName ?? '',
                              ),
                              child: const BlockedUserBanner(),
                            ),
                            Divider(
                              height: ChatViewBodyStyle.dividerSize,
                              thickness: ChatViewBodyStyle.dividerSize,
                              color: Theme.of(context).dividerColor,
                            ),
                          ],
                        );
                      },
                    ),
                    ValueListenableBuilder(
                      valueListenable:
                          getIt.get<ContactsManager>().getContactsNotifier(),
                      builder: (context, state, child) {
                        final contactToAdd = controller.contactToAdd(state);
                        if (contactToAdd == null) {
                          return const SizedBox();
                        }

                        return AddContactBanner(
                          onTap: () => showAddContactDialog(
                            context,
                            displayName: contactToAdd.displayName,
                            matrixId: contactToAdd.id,
                          ),
                          show: controller.showAddContactBanner,
                        );
                      },
                    ),
                    PinnedEventsView(controller),
                    if (controller.room!.pinnedEventIds.isNotEmpty)
                      Divider(
                        height: ChatViewBodyStyle.dividerSize,
                        thickness: ChatViewBodyStyle.dividerSize,
                        color: Theme.of(context).dividerColor,
                      ),
                    _audioPlayerWidget(),
                    SizedBox(
                      key: controller.stickyTimestampKey,
                      child: ValueListenableBuilder(
                        valueListenable: controller.stickyTimestampNotifier,
                        builder: (context, stickyTimestamp, child) {
                          return StickyTimestampWidget(
                            isStickyHeader: stickyTimestamp != null,
                            content: stickyTimestamp != null
                                ? stickyTimestamp.relativeTime(context)
                                : '',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ValueListenableBuilder(
              valueListenable: controller.draggingNotifier,
              builder: (context, dragging, _) {
                if (!dragging) return const SizedBox.shrink();
                return Container(
                  color: Theme.of(context)
                      .scaffoldBackgroundColor
                      .withOpacity(0.9),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.upload_outlined,
                    size: 100,
                  ),
                );
              },
            ),
            ValueListenableBuilder(
              valueListenable: controller.showEmojiPickerComposerNotifier,
              builder: (context, display, _) {
                if (!display) return const SizedBox.shrink();
                return Positioned(
                  bottom: 72,
                  right: 64,
                  child: MouseRegion(
                    onHover: (_) {
                      controller.showEmojiPickerComposerNotifier.value = true;
                    },
                    onExit: (_) async {
                      await Future.delayed(const Duration(seconds: 1));
                      controller.showEmojiPickerComposerNotifier.value = false;
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      width: ChatController.defaultMaxWidthReactionPicker,
                      height: ChatController.defaultMaxHeightReactionPicker,
                      decoration: BoxDecoration(
                        color: LinagoraRefColors.material().primary[100],
                        borderRadius: BorderRadius.circular(
                          24,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x0000004D).withOpacity(0.15),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                            spreadRadius: 3,
                          ),
                          BoxShadow(
                            color: const Color(0x00000026).withOpacity(0.3),
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: EmojiPicker(
                        emojiData: Matrix.of(context).emojiData,
                        recentEmoji:
                            controller.getRecentReactionsInteractor.execute(),
                        configuration: EmojiPickerConfiguration(
                          showRecentTab: true,
                          emojiStyle:
                              Theme.of(context).textTheme.headlineLarge!,
                          searchEmptyTextStyle: Theme.of(context)
                              .textTheme
                              .labelMedium!
                              .copyWith(
                                color:
                                    LinagoraRefColors.material().tertiary[30],
                              ),
                          searchEmptyWidget: SvgPicture.asset(
                            ImagePaths.icSearchEmojiEmpty,
                          ),
                          searchFocusNode: FocusNode(),
                        ),
                        itemBuilder: (
                          context,
                          emojiId,
                          emoji,
                          callback,
                        ) {
                          return MouseRegion(
                            onHover: (_) {},
                            child: EmojiItem(
                              textStyle:
                                  Theme.of(context).textTheme.headlineLarge!,
                              onTap: () {
                                callback(
                                  emojiId,
                                  emoji,
                                );
                              },
                              emoji: emoji,
                            ),
                          );
                        },
                        onEmojiSelected: (
                          emojiId,
                          emoji,
                        ) {
                          controller.typeEmoji(emoji);
                          controller.handleStoreRecentReactions(emoji);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCloseAudioPlayer() async {
    controller.matrix?.voiceMessageEvent.value = null;
    await controller.matrix?.audioPlayer.stop();
    await controller.matrix?.audioPlayer.dispose();
    controller.matrix?.currentAudioStatus.value =
        AudioPlayerStatus.notDownloaded;
  }

  Future<File> handleOggAudioFileIniOS(File file) async {
    Logs().v('Convert ogg audio file for iOS...');
    final convertedFile = File('${file.path}.caf');
    if (await convertedFile.exists() == false) {
      OpusCaf().convertOpusToCaf(file.path, convertedFile.path);
    }
    return convertedFile;
  }

  Future<void> _handlePlayAudioAgain(BuildContext context) async {
    File? file;
    MatrixFile? matrixFile;
    await controller.matrix?.audioPlayer.stop();
    await controller.matrix?.audioPlayer.dispose();
    controller.matrix?.currentAudioStatus.value =
        AudioPlayerStatus.notDownloaded;
    final currentEvent = controller.matrix?.voiceMessageEvent.value;

    controller.matrix?.currentAudioStatus.value = AudioPlayerStatus.downloading;

    try {
      matrixFile = await currentEvent?.downloadAndDecryptAttachment();

      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        final fileName = Uri.encodeComponent(
          currentEvent?.attachmentOrThumbnailMxcUrl()!.pathSegments.last ?? '',
        );
        file = File('${tempDir.path}/${fileName}_${matrixFile?.name}');

        await file.writeAsBytes(matrixFile?.bytes ?? []);

        if (Platform.isIOS &&
            matrixFile?.mimeType.toLowerCase() == 'audio/ogg') {
          file = await handleOggAudioFileIniOS(file);
        }
      }

      controller.matrix?.currentAudioStatus.value =
          AudioPlayerStatus.downloaded;
    } catch (e, s) {
      Logs().v('Could not download audio file', e, s);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toLocalizedString(context)),
        ),
      );
      rethrow;
    }
    if (!context.mounted) return;

    if (controller.matrix == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.of(context)!.couldNotPlayAudioFile),
        ),
      );
      return;
    }

    controller.matrix!.audioPlayer = AudioPlayer();

    if (file != null) {
      await controller.matrix!.audioPlayer.setFilePath(file.path);
    } else if (matrixFile != null) {
      await controller.matrix!.audioPlayer
          .setAudioSource(MatrixFileAudioSource(matrixFile));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.of(context)!.couldNotPlayAudioFile),
        ),
      );
      return;
    }

    controller.matrix!.audioPlayer.play().onError((e, s) {
      Logs().e('Could not play audio file', e, s);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e?.toLocalizedString(context) ??
                L10n.of(context)!.couldNotPlayAudioFile,
          ),
        ),
      );
    });
  }

  Future<void> _handlePlayOrPauseAudioPlayer(BuildContext context) async {
    final audioPlayer = controller.matrix?.audioPlayer;
    if (audioPlayer == null) return;
    if (audioPlayer.isAtEndPosition) {
      await _handlePlayAudioAgain(context);
      return;
    }

    if (audioPlayer.playing == true) {
      audioPlayer.pause();
    } else {
      audioPlayer.play();
    }
  }

  Widget _audioPlayerWidget() {
    return ValueListenableBuilder(
      valueListenable: controller.matrix?.currentAudioStatus ??
          ValueNotifier<AudioPlayerStatus>(
            AudioPlayerStatus.notDownloaded,
          ),
      builder: (context, status, _) {
        return ValueListenableBuilder(
          valueListenable: controller.matrix?.voiceMessageEvent ??
              ValueNotifier<Event?>(null),
          builder: (context, hasEvent, _) {
            if (hasEvent == null) {
              return const SizedBox.shrink();
            }
            final audioPlayer = controller.matrix?.audioPlayer;
            return StreamBuilder<Object>(
              stream: StreamGroup.merge([
                controller.matrix?.audioPlayer.positionStream
                        .asBroadcastStream() ??
                    Stream.value(Duration.zero),
                controller.matrix?.audioPlayer.playerStateStream
                        .asBroadcastStream() ??
                    Stream.value(Duration.zero),
                controller.matrix?.audioPlayer.speedStream
                        .asBroadcastStream() ??
                    Stream.value(Duration.zero),
              ]),
              builder: (context, snapshot) {
                final maxPosition =
                    audioPlayer?.duration?.inMilliseconds.toDouble() ?? 1.0;
                final currentPosition = status == AudioPlayerStatus.downloading
                    ? 0
                    : audioPlayer?.position.inMilliseconds.toDouble() ?? 0.0;
                final progress = maxPosition > 0
                    ? (currentPosition / maxPosition).clamp(0.0, 1.0)
                    : 0.0;
                return Container(
                  constraints: const BoxConstraints(maxHeight: 40),
                  decoration: BoxDecoration(
                    color: LinagoraSysColors.material().onPrimary,
                    border: Border(
                      top: BorderSide(
                        color: LinagoraStateLayer(
                          LinagoraSysColors.material().surfaceTint,
                        ).opacityLayer3,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 37,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            TwakeIconButton(
                              size: 20,
                              onTap: () async =>
                                  _handlePlayOrPauseAudioPlayer(context),
                              iconColor: LinagoraSysColors.material().primary,
                              icon: audioPlayer?.playing == true &&
                                      audioPlayer?.isAtEndPosition == false
                                  ? Icons.pause_outlined
                                  : Icons.play_arrow,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _displaySenderNameWhenPlayingAudio(
                                hasEvent,
                                audioPlayer?.position.minuteSecondString ?? '',
                              ),
                            ),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => _toggleSpeed(audioPlayer),
                                  child: Center(
                                    child: SvgPicture.asset(
                                      _displayAudioSpeed(
                                        audioPlayer?.speed ?? 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TwakeIconButton(
                                  onTap: () async => _handleCloseAudioPlayer(),
                                  icon: Icons.close,
                                  iconColor:
                                      LinagoraRefColors.material().tertiary[30],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 2,
                        backgroundColor: LinagoraStateLayer(
                          LinagoraSysColors.material().surfaceTint,
                        ).opacityLayer3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          LinagoraSysColors.material().primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _displayAudioSpeed(double int) {
    switch (int) {
      case 0.5:
        return ImagePaths.icAudioSpeed0_5x;
      case 1.0:
        return ImagePaths.icAudioSpeed1x;
      case 1.5:
        return ImagePaths.icAudioSpeed1_5x;
      case 2.0:
        return ImagePaths.icAudioSpeed2x;
      default:
        return ImagePaths.icAudioSpeed1x;
    }
  }

  void _toggleSpeed(AudioPlayer? audioPlayer) async {
    if (audioPlayer == null) return;
    switch (audioPlayer.speed) {
      case 0.5:
        await audioPlayer.setSpeed(0.75);
        break;
      case 0.75:
        await audioPlayer.setSpeed(1.0);
        break;
      case 1.0:
        await audioPlayer.setSpeed(1.5);
        break;
      case 1.5:
        await audioPlayer.setSpeed(2);
        break;
      case 2.0:
        await audioPlayer.setSpeed(0.5);
        break;
      default:
        await audioPlayer.setSpeed(1.0);
        break;
    }
  }

  Widget _displaySenderNameWhenPlayingAudio(
    Event event,
    String duration,
  ) {
    return FutureBuilder<User?>(
      future: event.fetchSenderUser(),
      builder: (context, snapshot) {
        final displayName = snapshot.data?.calcDisplayname() ??
            event.senderFromMemoryOrFallback.calcDisplayname();
        return Text(
          "${displayName.shortenDisplayName(
            maxCharacters: DisplayNameWidget.maxCharactersDisplayNameBubble,
          )}  $duration",
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontFamily: 'Inter',
                color: LinagoraRefColors.material().neutral[50],
              ),
          maxLines: 1,
          overflow: TextOverflow.clip,
        );
      },
    );
  }

  Widget _inputMessageWidget(BuildContext context) {
    return Container(
      decoration: controller.responsive.isMobile(context)
          ? BoxDecoration(
              color: LinagoraSysColors.material().surface,
              border: Border(
                top: BorderSide(
                  color: LinagoraStateLayer(
                    LinagoraSysColors.material().surfaceTint,
                  ).opacityLayer3,
                ),
              ),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ConnectionStatusHeader(),
          ValueListenableBuilder(
            valueListenable: controller.editEventNotifier,
            builder: (context, editEvent, _) {
              if (!controller.responsive.isMobile(context)) {
                return const SizedBox.shrink();
              }

              if (editEvent == null) return const SizedBox.shrink();
              return Padding(
                padding: ChatViewBodyStyle.inputBarPadding(context),
                child: EditDisplay(
                  editEventNotifier: controller.editEventNotifier,
                  onCloseEditAction: controller.cancelEditEventAction,
                  timeline: controller.timeline,
                ),
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: controller.isBlockedUserNotifier,
            builder: (context, isBlocked, child) {
              if (!isBlocked) {
                return child ?? const SizedBox();
              }

              return const BlockedMessageView();
            },
            child: Padding(
              padding: ChatViewBodyStyle.inputBarPadding(context)
                  .add(const EdgeInsetsGeometry.symmetric(vertical: 8)),
              child: ChatInputRow(controller),
            ),
          ),
        ],
      ),
    );
  }
}
