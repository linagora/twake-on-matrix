import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fluffychat/pages/chat/events/audio_player_style.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:just_audio/just_audio.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';

class AudioPlayerWidget extends StatefulWidget {
  final Event event;
  final bool ownMessage;
  static String? currentId;
  static const int maxWavesCount = 40;

  const AudioPlayerWidget(this.event, {this.ownMessage = false, Key? key})
      : super(key: key);

  @override
  AudioPlayerState createState() => AudioPlayerState();
}

enum AudioPlayerStatus { notDownloaded, downloading, downloaded }

class AudioPlayerState extends State<AudioPlayerWidget> {
  AudioPlayerStatus status = AudioPlayerStatus.notDownloaded;
  AudioPlayer? audioPlayer;

  StreamSubscription? onAudioPositionChanged;
  StreamSubscription? onDurationChanged;
  StreamSubscription? onPlayerStateChanged;
  StreamSubscription? onPlayerError;

  String? statusText;
  int currentPosition = 0;
  double maxPosition = 0;

  MatrixFile? matrixFile;
  File? audioFile;

  @override
  void dispose() {
    if (audioPlayer?.playerState.playing == true) {
      audioPlayer?.stop();
    }
    onAudioPositionChanged?.cancel();
    onDurationChanged?.cancel();
    onPlayerStateChanged?.cancel();
    onPlayerError?.cancel();

    super.dispose();
  }

  Future<void> _downloadAction() async {
    if (status != AudioPlayerStatus.notDownloaded) return;
    setState(() => status = AudioPlayerStatus.downloading);
    try {
      final matrixFile = await widget.event.downloadAndDecryptAttachment();
      File? file;

      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        final fileName = Uri.encodeComponent(
          widget.event.attachmentOrThumbnailMxcUrl()!.pathSegments.last,
        );
        file = File('${tempDir.path}/${fileName}_${matrixFile.name}');
        if (matrixFile.bytes == null) {
          return;
        }
        await file.writeAsBytes(matrixFile.bytes!);
      }

      setState(() {
        audioFile = file;
        this.matrixFile = matrixFile;
        status = AudioPlayerStatus.downloaded;
      });
      _playAction();
    } catch (e, s) {
      Logs().v('Could not download audio file', e, s);
      TwakeSnackBar.show(
        context,
        e.toLocalizedString(context),
      );
    }
  }

  void _playAction() async {
    final audioPlayer = this.audioPlayer ??= AudioPlayer();
    if (AudioPlayerWidget.currentId != widget.event.eventId) {
      if (AudioPlayerWidget.currentId != null) {
        if (audioPlayer.playerState.playing) {
          await audioPlayer.stop();
          setState(() {});
        }
      }
      AudioPlayerWidget.currentId = widget.event.eventId;
    }
    if (audioPlayer.playerState.playing) {
      await audioPlayer.pause();
      return;
    } else if (audioPlayer.position != Duration.zero) {
      await audioPlayer.play();
      return;
    }

    onAudioPositionChanged ??= audioPlayer.positionStream.listen((state) {
      if (maxPosition <= 0) return;
      setState(() {
        statusText =
            '${state.inMinutes.toString().padLeft(2, '0')}:${(state.inSeconds % 60).toString().padLeft(2, '0')}';
        currentPosition = ((state.inMilliseconds.toDouble() / maxPosition) *
                AudioPlayerWidget.maxWavesCount)
            .round();
      });
    });
    onDurationChanged ??= audioPlayer.durationStream.listen((max) {
      if (max == null || max == Duration.zero) return;
      setState(() => maxPosition = max.inMilliseconds.toDouble());
    });
    onPlayerStateChanged ??=
        audioPlayer.playingStream.listen((_) => setState(() {}));
    final audioFile = this.audioFile;
    if (audioFile != null) {
      audioPlayer.setFilePath(audioFile.path);
    } else {
      await audioPlayer.setAudioSource(MatrixFileAudioSource(matrixFile!));
    }
    audioPlayer.play().catchError((e, s) {
      TwakeSnackBar.show(
        context,
        L10n.of(context)!.oopsSomethingWentWrong,
      );
      Logs().w('Error while playing audio', e, s);
    });
  }

  static const double buttonSize = 36;

  String? get _durationString {
    final durationInt = widget.event.content
        .tryGetMap<String, dynamic>('info')
        ?.tryGet<int>('duration');
    if (durationInt == null) return null;
    final duration = Duration(milliseconds: durationInt);
    return '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  List<int> _getWaveform() {
    final eventWaveForm = widget.event.content
        .tryGetMap<String, dynamic>('org.matrix.msc1767.audio')
        ?.tryGetList<int>('waveform');
    if (eventWaveForm == null) {
      return List<int>.generate(
          AudioPlayerWidget.maxWavesCount, (i) => Random().nextInt(150) + 50);
    }
    while (eventWaveForm.length < AudioPlayerWidget.maxWavesCount) {
      for (var i = 0; i < eventWaveForm.length; i = i + 2) {
        eventWaveForm.insert(i, eventWaveForm[i]);
      }
    }
    var i = 0;
    final step =
        (eventWaveForm.length / AudioPlayerWidget.maxWavesCount).round();
    while (eventWaveForm.length > AudioPlayerWidget.maxWavesCount) {
      eventWaveForm.removeAt(i);
      i = (i + step) % AudioPlayerWidget.maxWavesCount;
    }
    return eventWaveForm;
  }

  late final List<int> waveform;

  @override
  void initState() {
    super.initState();
    waveform = _getWaveform();
  }

  @override
  Widget build(BuildContext context) {
    final statusText = this.statusText ??= _durationString ?? '00:00';
    return Padding(
      padding: EdgeInsets.all(16 * AppConfig.bubbleSizeFactor),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: status == AudioPlayerStatus.downloading
                ? CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : InkWell(
                    borderRadius: BorderRadius.circular(64),
                    child: Material(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(64),
                      child: Icon(
                        audioPlayer?.playerState.playing == true
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    onLongPress: () => widget.event.saveFile(context),
                    onTap: () {
                      if (status == AudioPlayerStatus.downloaded) {
                        _playAction();
                      } else {
                        _downloadAction();
                      }
                    },
                  ),
          ),
          const SizedBox(width: AudioPlayerStyle.playAndWaveGap),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    for (var i = 0; i < AudioPlayerWidget.maxWavesCount; i++)
                      Expanded(
                        child: InkWell(
                          onTap: () => audioPlayer?.seek(
                            Duration(
                              milliseconds: (maxPosition /
                                          AudioPlayerWidget.maxWavesCount)
                                      .round() *
                                  i,
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: AudioPlayerStyle.waveColor(
                                      context, widget.ownMessage)
                                  ?.withOpacity(currentPosition > i ? 1 : 0.5),
                              borderRadius: BorderRadius.circular(64),
                            ),
                            height: AudioPlayerStyle.waveHeight(
                                waveform[i], waveform.max),
                          ),
                        ),
                      ),
                  ],
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    statusText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AudioPlayerStyle.timerColor(
                              context, widget.ownMessage),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// To use a MatrixFile as an AudioSource for the just_audio package
class MatrixFileAudioSource extends StreamAudioSource {
  final MatrixFile file;
  MatrixFileAudioSource(this.file);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= file.bytes?.length ?? 0;
    return StreamAudioResponse(
      sourceLength: file.bytes?.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(file.bytes?.sublist(start, end) ?? []),
      contentType: file.mimeType,
    );
  }
}
