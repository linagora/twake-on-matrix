import 'dart:io';

import 'package:async/async.dart';
import 'package:fluffychat/pages/chat/events/audio_message/audio_play_extension.dart';
import 'package:fluffychat/pages/chat/events/audio_message/audio_player_widget.dart';
import 'package:fluffychat/pages/chat/events/message/display_name_widget.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:just_audio/just_audio.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:opus_caf_converter_dart/opus_caf_converter_dart.dart';
import 'package:path_provider/path_provider.dart';

class ChatAudioPlayerWidget extends StatelessWidget {
  final MatrixState? matrix;
  final bool enableBorder;

  const ChatAudioPlayerWidget({
    required this.matrix,
    this.enableBorder = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final defaultAudioStatus = ValueNotifier<AudioPlayerStatus>(
      AudioPlayerStatus.notDownloaded,
    );
    final defaultEvent = ValueNotifier<Event?>(null);
    return ValueListenableBuilder(
      valueListenable: matrix?.currentAudioStatus ?? defaultAudioStatus,
      builder: (context, status, _) {
        return ValueListenableBuilder(
          valueListenable: matrix?.voiceMessageEvent ?? defaultEvent,
          builder: (context, hasEvent, _) {
            if (hasEvent == null) {
              return const SizedBox.shrink();
            }
            final audioPlayer = matrix?.audioPlayer;
            return StreamBuilder<Object>(
              stream: StreamGroup.merge([
                matrix?.audioPlayer.positionStream.asBroadcastStream() ??
                    Stream.value(Duration.zero),
                matrix?.audioPlayer.playerStateStream.asBroadcastStream() ??
                    Stream.value(Duration.zero),
                matrix?.audioPlayer.speedStream.asBroadcastStream() ??
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
                    border: enableBorder
                        ? Border(
                            top: BorderSide(
                              color: LinagoraStateLayer(
                                LinagoraSysColors.material().surfaceTint,
                              ).opacityLayer3,
                            ),
                          )
                        : null,
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
                              icon:
                                  audioPlayer?.playing == true &&
                                      audioPlayer?.isAtEndPosition == false
                                  ? Icons.pause_outlined
                                  : Icons.play_arrow,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _DisplaySenderNameWhenPlayingAudio(
                                event: hasEvent,
                                duration:
                                    audioPlayer?.position.minuteSecondString ??
                                    '',
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

  Future<void> _handleCloseAudioPlayer() async {
    matrix?.voiceMessageEvent.value = null;
    matrix?.cancelAudioPlayerAutoDispose();
    await matrix?.audioPlayer.stop();
    await matrix?.audioPlayer.dispose();
    matrix?.currentAudioStatus.value = AudioPlayerStatus.notDownloaded;
  }

  Future<File> _handleOggAudioFileIniOS(File file) async {
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
    await matrix?.audioPlayer.stop();
    await matrix?.audioPlayer.dispose();
    matrix?.currentAudioStatus.value = AudioPlayerStatus.notDownloaded;
    final currentEvent = matrix?.voiceMessageEvent.value;

    matrix?.currentAudioStatus.value = AudioPlayerStatus.downloading;

    try {
      matrixFile = await currentEvent?.downloadAndDecryptAttachment();

      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        final mxcUrl = currentEvent?.attachmentOrThumbnailMxcUrl();
        final fileName = Uri.encodeComponent(mxcUrl?.pathSegments.last ?? '');
        file = File('${tempDir.path}/${fileName}_${matrixFile?.name}');

        final bytes = matrixFile?.bytes;

        if (bytes == null || bytes.isEmpty) {
          throw Exception('Downloaded file has no content');
        }
        await file.writeAsBytes(bytes);

        if (Platform.isIOS &&
            matrixFile?.mimeType.toLowerCase() == 'audio/ogg') {
          file = await _handleOggAudioFileIniOS(file);
        }
      }

      matrix?.currentAudioStatus.value = AudioPlayerStatus.downloaded;
    } catch (e, s) {
      Logs().v('Could not download audio file', e, s);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toLocalizedString(context))));
      rethrow;
    }
    if (!context.mounted) return;

    if (matrix == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.of(context)!.couldNotPlayAudioFile)),
      );
      return;
    }

    matrix!.audioPlayer = AudioPlayer();

    if (file != null) {
      await matrix?.audioPlayer.setFilePath(file.path);
    } else if (matrixFile != null) {
      await matrix?.audioPlayer.setAudioSource(
        MatrixFileAudioSource(matrixFile),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.of(context)!.couldNotPlayAudioFile)),
      );
      return;
    }

    // Set up auto-dispose listener managed globally in MatrixState
    matrix?.setupAudioPlayerAutoDispose();

    matrix?.audioPlayer.play().onError((e, s) {
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
    final audioPlayer = matrix?.audioPlayer;
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

  String _displayAudioSpeed(double speed) {
    switch (speed) {
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

  Future<void> _toggleSpeed(AudioPlayer? audioPlayer) async {
    if (audioPlayer == null) return;
    switch (audioPlayer.speed) {
      case 0.5:
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
}

/// Private widget to display sender name and audio duration.
class _DisplaySenderNameWhenPlayingAudio extends StatelessWidget {
  final Event event;
  final String duration;

  const _DisplaySenderNameWhenPlayingAudio({
    required this.event,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: event.fetchSenderUser(),
      builder: (context, snapshot) {
        final displayName =
            snapshot.data?.calcDisplayname() ??
            event.senderFromMemoryOrFallback.calcDisplayname();
        return Text(
          "${displayName.shortenDisplayName(maxCharacters: DisplayNameWidget.maxCharactersDisplayNameBubble)}  $duration",
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
}
