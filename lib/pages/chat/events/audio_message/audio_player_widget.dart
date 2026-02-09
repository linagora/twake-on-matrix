import 'dart:async';
import 'package:async/async.dart';
import 'package:fluffychat/pages/chat/events/audio_message/audio_play_extension.dart';
import 'package:fluffychat/pages/chat/events/audio_message/audio_player_style.dart';
import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/pages/chat/seen_by_row.dart';
import 'package:fluffychat/presentation/mixins/audio_mixin.dart';
import 'package:fluffychat/presentation/mixins/event_filter_mixin.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/download_file_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/room_status_extension.dart';
import 'package:fluffychat/utils/size_string.dart';
import 'package:fluffychat/widgets/file_widget/circular_loading_download_widget.dart';
import 'package:fluffychat/widgets/file_widget/file_tile_widget.dart';
import 'package:fluffychat/widgets/file_widget/message_file_tile_style.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

import 'package:fluffychat/utils/localized_exception_extension.dart';

class AudioPlayerWidget extends StatefulWidget {
  final Color color;
  final Event event;
  final Timeline timeline;

  static const int wavesCount = 80;

  const AudioPlayerWidget(
    this.event, {
    this.color = Colors.black,
    super.key,
    required this.timeline,
  });

  @override
  AudioPlayerState createState() => AudioPlayerState();
}

enum AudioPlayerStatus { notDownloaded, downloading, downloaded }

class AudioPlayerState extends State<AudioPlayerWidget>
    with AudioMixin, AutomaticKeepAliveClientMixin, EventFilterMixin {
  final List<double> _calculatedWaveform = [];

  final ValueNotifier<Duration> _durationNotifier =
      ValueNotifier(Duration.zero);

  late final MatrixState matrix;

  String get fileName {
    return widget.event.content.tryGet<String>('body') ?? '';
  }

  String? get fileSize {
    final size = widget.event.content
        .tryGetMap<String, dynamic>('info')
        ?.tryGet<int>('size');
    return size?.sizeString;
  }

  String get mimeType {
    return widget.event.content
            .tryGetMap<String, dynamic>('info')
            ?.tryGet<String>('mimeType') ??
        '';
  }

  bool get isAudio {
    return widget.event.content
            .tryGetMap<String, dynamic>('org.matrix.msc1767.audio') !=
        null;
  }

  Future<void> _onButtonTap() async {
    if (widget.event.isSending()) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(matrix.context).clearMaterialBanners();
    });
    if (matrix.voiceMessageEvent.value?.eventId == widget.event.eventId) {
      if (matrix.audioPlayer?.isAtEndPosition == true) {
        matrix.voiceMessageEvent.value = null;
        await matrix.audioPlayer?.stop();
        await matrix.audioPlayer?.dispose();
        matrix.currentAudioStatus.value = AudioPlayerStatus.notDownloaded;
        await _onButtonTap();
        return;
      }
      if (matrix.audioPlayer?.playing == true) {
        matrix.audioPlayer?.pause();
      } else {
        matrix.audioPlayer?.play().onError((e, s) {
          Logs().e('Could not play audio file', e, s);
          matrix.voiceMessageEvent.value = null;
          matrix.currentAudioStatus.value = AudioPlayerStatus.notDownloaded;
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
      return;
    }

    final audioPending = await initAudioEventsUpToClicked(
      client: matrix.client,
      room: widget.event.room,
      clickedEvent: widget.event,
    );

    matrix.voiceMessageEvents.value = audioPending.events;

    await matrix.autoPlayAudio(currentEvent: widget.event, context: context);
  }

  @override
  void initState() {
    super.initState();
    matrix = Matrix.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isCurrentEvent =
          matrix.voiceMessageEvent.value?.eventId == widget.event.eventId;
      if (matrix.voiceMessageEvent.value == null || isCurrentEvent) {
        matrix.currentAudioStatus.value = AudioPlayerStatus.notDownloaded;
      }
      final durationInt = widget.event.content
          .tryGetMap<String, dynamic>('org.matrix.msc1767.audio')
          ?.tryGet<int>('duration');
      if (durationInt != null) {
        _durationNotifier.value = Duration(milliseconds: durationInt);
      }
      final maxBubbleWaves = AudioPlayerStyle.maxWaveCount(context);
      final waveForm = calculateWaveForm(
            eventWaveForm: widget.event.content
                .tryGetMap<String, dynamic>('org.matrix.msc1767.audio')
                ?.tryGetList<int>('waveform'),
            waveCount: calculateWaveCountAuto(
              minWaves: AudioPlayerStyle.minWaveCount,
              maxWaves: _calculatedWaveform.isEmpty
                  ? maxBubbleWaves
                  : _calculatedWaveform.length,
              durationInSeconds: _durationNotifier.value.inSeconds,
            ),
            maxBubbleWaveCount: maxBubbleWaves,
          ) ??
          [];

      final waveFromHeight = calculateWaveHeight(
        waveform: waveForm,
        minHeight: AudioPlayerStyle.minWaveHeight,
        maxHeight: AudioPlayerStyle.maxWaveHeight,
      );

      if (_calculatedWaveform.isEmpty) {
        _calculatedWaveform.addAll(waveFromHeight);
        if (matrix.voiceMessageEvent.value == null || isCurrentEvent) {
          matrix.currentAudioStatus.value = AudioPlayerStatus.downloaded;
        }
      }

      if (matrix.voiceMessageEvent.value?.eventId == widget.event.eventId) {
        ScaffoldMessenger.of(matrix.context).clearMaterialBanners();
      }
    });
  }

  @override
  void dispose() {
    if (!PlatformInfos.isMobile) {
      final currentEventId = widget.event.eventId;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Only dispose if this event is currently playing
        if (matrix.voiceMessageEvent.value?.eventId == currentEventId) {
          // Stop and dispose audio player asynchronously to avoid blocking
          // dispose
          final playerToDispose = matrix.audioPlayer;
          if (playerToDispose != null) {
            await playerToDispose.stop();
            await playerToDispose.dispose();
          }

          // Schedule value updates for after the current frame to avoid
          // setState() during widget tree lock
          matrix.currentAudioStatus.value = AudioPlayerStatus.notDownloaded;
          matrix.voiceMessageEvent.value = null;
        }
      });
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ValueListenableBuilder(
      valueListenable: matrix.currentAudioStatus,
      builder: (context, status, _) {
        return ValueListenableBuilder(
          valueListenable: matrix.voiceMessageEvent,
          builder: (context, event, _) {
            final audioPlayer = event?.eventId != widget.event.eventId
                ? null
                : matrix.audioPlayer;

            return StreamBuilder<Object>(
              stream: audioPlayer == null
                  ? null
                  : StreamGroup.merge([
                      audioPlayer.positionStream.asBroadcastStream(),
                      audioPlayer.playerStateStream.asBroadcastStream(),
                    ]),
              builder: (context, snapshot) {
                final maxPosition =
                    audioPlayer?.duration?.inMilliseconds.toDouble() ?? 1.0;
                var currentPosition = status == AudioPlayerStatus.downloading
                    ? 0
                    : audioPlayer?.position.inMilliseconds.toDouble() ?? 0.0;
                if (currentPosition > maxPosition) {
                  currentPosition = maxPosition;
                }

                final wavePosition = (currentPosition / maxPosition) *
                    calculateWaveCountAuto(
                      minWaves: AudioPlayerStyle.minWaveCount,
                      maxWaves: _calculatedWaveform.length,
                      durationInSeconds: _durationNotifier.value.inSeconds,
                    );

                return Padding(
                  padding: const EdgeInsets.only(
                    top: 8.0,
                    bottom: 16.0,
                    left: 8.0,
                    right: 8.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MessageStyle.messageBubbleWidth(context),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _playButtonBuilder(
                              status: status,
                              audioPlayer: audioPlayer,
                              isCurrentAudio:
                                  event?.eventId == widget.event.eventId,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_calculatedWaveform.isEmpty) ...[
                                    Text(
                                      fileName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ] else
                                    Row(
                                      children: List.generate(
                                        _calculatedWaveform.length,
                                        (index) {
                                          return _waveItemBuilder(
                                            index: index,
                                            waveHeight:
                                                _calculatedWaveform[index],
                                            wavePosition: wavePosition,
                                          );
                                        },
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  _audioMessageTimeBuilder(
                                    duration: audioPlayer == null
                                        ? _durationNotifier
                                            .value.minuteSecondString
                                        : audioPlayer
                                            .position.minuteSecondString,
                                  ),
                                ],
                              ),
                            ),
                          ],
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

  Widget _audioMessageTimeBuilder({
    required String duration,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (isAudio) ...[
          Text(
            duration,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: LinagoraRefColors.material().tertiary[30],
                ),
          ),
        ] else ...[
          if (fileSize != null)
            TextInformationOfFile(
              value: fileSize!,
              style: AudioPlayerStyle.textInformationStyle(context),
            ),
        ],
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.event.isPinned) ...[
                  TwakeIconButton(
                    tooltip: L10n.of(context)!.pin,
                    icon: Icons.push_pin_outlined,
                    size: MessageStyle.pushpinIconSize,
                    paddingAll: MessageStyle.paddingAllPushpin,
                    margin: EdgeInsets.zero,
                    iconColor: LinagoraRefColors.material().neutral[50],
                  ),
                  const SizedBox(width: 4.0),
                ],
                Text(
                  DateFormat("HH:mm").format(
                    widget.event.originServerTs,
                  ),
                  textScaler: const TextScaler.linear(
                    1.0,
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.merge(
                        TextStyle(
                          color: LinagoraRefColors.material().tertiary[30],
                          letterSpacing: 0.4,
                        ),
                      ),
                ),
                const SizedBox(width: 4),
                SeenByRow(
                  timelineOverlayMessage: widget.event.timelineOverlayMessage,
                  participants: widget.timeline.room.getParticipants(),
                  getSeenByUsers: widget.event.room.getSeenByUsers(
                    widget.timeline,
                    eventId: widget.event.eventId,
                  ),
                  eventStatus: widget.event.status,
                  event: widget.event,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _waveItemBuilder({
    required int index,
    required double waveHeight,
    required double wavePosition,
  }) {
    return Container(
      height: waveHeight,
      width: 2,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(
        horizontal: 1,
      ),
      decoration: BoxDecoration(
        color: index < wavePosition
            ? LinagoraSysColors.material().primary
            : LinagoraSysColors.material().primary.withAlpha(70),
        borderRadius: BorderRadius.circular(
          64,
        ),
      ),
    );
  }

  Widget _playButtonBuilder({
    required AudioPlayerStatus status,
    required AudioPlayer? audioPlayer,
    bool isCurrentAudio = false,
  }) {
    return InkWell(
      onTap: () async => _onButtonTap(),
      child: status == AudioPlayerStatus.downloading && isCurrentAudio
          ? Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularLoadingDownloadWidget(
                    style: MessageFileTileStyle(),
                  ),
                ),
                Container(
                  width: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    status == AudioPlayerStatus.downloaded
                        ? Icons.arrow_downward
                        : Icons.play_arrow,
                    color: Theme.of(context).colorScheme.surface,
                    size: 24,
                  ),
                ),
              ],
            )
          : Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                audioPlayer?.playing == true &&
                        audioPlayer?.isAtEndPosition == false
                    ? Icons.pause_outlined
                    : Icons.play_arrow,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
