import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/chat/events/audio_message/audio_play_extension.dart';
import 'package:fluffychat/pages/chat/events/audio_message/audio_player_widget.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:just_audio/just_audio.dart';
import 'package:matrix/matrix.dart';
import 'package:opus_caf_converter_dart/opus_caf_converter_dart.dart';
import 'package:path_provider/path_provider.dart';

/// Mixin that provides audio player functionality for voice messages.
///
/// This mixin manages audio playback state, auto-play queue, and cleanup.
/// It should be used with State classes that need audio playback capabilities.
mixin AudioPlayerMixin<T extends StatefulWidget> on State<T> {
  AudioPlayer? audioPlayer;

  final ValueNotifier<Event?> voiceMessageEvent = ValueNotifier(null);

  final ValueNotifier<List<Event>> voiceMessageEvents = ValueNotifier([]);

  final ValueNotifier<AudioPlayerStatus> currentAudioStatus =
      ValueNotifier(AudioPlayerStatus.notDownloaded);

  StreamSubscription<PlayerState>? _audioPlayerStateSubscription;

  /// Sets up the audio player with auto-dispose listener when playback
  /// completes.
  ///
  /// This method should be called after setting up a new audio source.
  /// It automatically cleans up the audio player and resets state when
  /// playback finishes.
  void setupAudioPlayerAutoDispose() {
    _audioPlayerStateSubscription?.cancel();
    _audioPlayerStateSubscription =
        audioPlayer?.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        Logs().d(
          'setupAudioPlayerAutoDispose: Current audio message - ${voiceMessageEvents.value}',
        );

        if (voiceMessageEvents.value.isEmpty) {
          // If no messages in queue, clean up everything
          await cleanupAudioPlayer();
          return;
        }

        // Remove the completed message from the list
        final updatedVoiceMessageEvent = voiceMessageEvents.value
            .where((e) => e.eventId != voiceMessageEvent.value?.eventId)
            .toList();

        Logs().d(
          'setupAudioPlayerAutoDispose: Remaining audio message - $updatedVoiceMessageEvent',
        );

        voiceMessageEvents.value = updatedVoiceMessageEvent;

        // Check if this was the last message
        if (voiceMessageEvents.value.isEmpty) {
          Logs().d(
            'setupAudioPlayerAutoDispose: Last audio finished, cleaning up all state',
          );
          // Clear all audio player state since this was the last message
          await cleanupAudioPlayer();
          return;
        }

        // There are more messages to play
        voiceMessageEvent.value = null;
        currentAudioStatus.value = AudioPlayerStatus.notDownloaded;

        final nextAudioMessage = voiceMessageEvents.value.first;
        await autoPlayAudio(
          currentEvent: nextAudioMessage,
        );
      }
    });
  }

  /// Automatically plays an audio message.
  ///
  /// Downloads, decrypts, and plays the audio file for the given event.
  /// Handles platform-specific audio format conversions (e.g., OGG to CAF on iOS).
  Future<void> autoPlayAudio({
    required Event currentEvent,
  }) async {
    voiceMessageEvent.value = currentEvent;
    File? file;
    MatrixFile? matrixFile;

    currentAudioStatus.value = AudioPlayerStatus.downloading;
    try {
      matrixFile = await currentEvent.downloadAndDecryptAttachment();

      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        final mxcUrl = currentEvent.attachmentOrThumbnailMxcUrl();
        if (mxcUrl == null) {
          throw Exception('Event has no attachment URL');
        }
        final fileName = Uri.encodeComponent(
          mxcUrl.pathSegments.last,
        );
        file = File('${tempDir.path}/${fileName}_${matrixFile.name}');

        if (matrixFile.bytes?.isEmpty == true) {
          throw Exception('Downloaded file has no content');
        }

        await file.writeAsBytes(matrixFile.bytes ?? []);

        if (Platform.isIOS &&
            matrixFile.mimeType.toLowerCase() == 'audio/ogg') {
          final oggAudioFileIniOS = await handleOggAudioFileIniOS(file);
          if (oggAudioFileIniOS != null) {
            file = oggAudioFileIniOS;
          }
        }
      }

      currentAudioStatus.value = AudioPlayerStatus.downloaded;
    } catch (e, s) {
      Logs().e('Could not download audio file', e, s);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toLocalizedString(context)),
          ),
        );
      }
      currentAudioStatus.value = AudioPlayerStatus.notDownloaded;
      return;
    }
    if (voiceMessageEvent.value?.eventId != currentEvent.eventId) return;

    // Initialize audio player before use
    await audioPlayer?.stop();
    await audioPlayer?.dispose();

    audioPlayer = AudioPlayer();
    voiceMessageEvent.value = currentEvent;

    if (file != null) {
      await audioPlayer?.setFilePath(file.path);
    } else {
      await audioPlayer?.setAudioSource(MatrixFileAudioSource(matrixFile));
    }

    // Set up auto-dispose listener managed globally in MatrixState
    setupAudioPlayerAutoDispose();

    audioPlayer?.play().onError((e, s) {
      Logs().e('Could not play audio file', e, s);
      // Reset state on playback error
      voiceMessageEvent.value = null;
      currentAudioStatus.value = AudioPlayerStatus.notDownloaded;
      if (!context.mounted) return;
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

  /// Converts OGG audio files to CAF format for iOS compatibility.
  ///
  /// Returns the converted file if successful, null otherwise.
  Future<File?> handleOggAudioFileIniOS(File file) async {
    try {
      Logs().v('Convert ogg audio file for iOS...');
      final convertedFile = File('${file.path}.caf');
      if (await convertedFile.exists() == false) {
        OpusCaf().convertOpusToCaf(file.path, convertedFile.path);
        // Verify conversion succeeded
        if (await convertedFile.exists() == false) {
          Logs().w(
            'AudioPlayerMixin::handleOggAudioFileIniOS: OGG to CAF conversion failed - converted file does not exist',
          );
          return null;
        }
      }
      return convertedFile;
    } catch (e, s) {
      Logs().e('Could not convert ogg audio file for iOS', e, s);
      return null;
    }
  }

  /// Cancels the audio player auto-dispose subscription.
  void cancelAudioPlayerAutoDispose() {
    _audioPlayerStateSubscription?.cancel();
    _audioPlayerStateSubscription = null;
  }

  /// Cleans up the audio player and clears playing lists.
  ///
  /// Should be called when logging out or switching accounts to ensure
  /// audio playback is properly stopped and state is reset.
  Future<void> cleanupAudioPlayer() async {
    try {
      await audioPlayer?.pause();
      await audioPlayer?.stop();
      await audioPlayer?.dispose();
      audioPlayer = null;
      _audioPlayerStateSubscription?.cancel();
      _audioPlayerStateSubscription = null;
      voiceMessageEvents.value = [];
      voiceMessageEvent.value = null;
      currentAudioStatus.value = AudioPlayerStatus.notDownloaded;
      Logs().d('AudioPlayerMixin::cleanupAudioPlayer: Audio player cleaned up');
    } catch (e) {
      Logs().e('AudioPlayerMixin::cleanupAudioPlayer: Error - $e');
    }
  }

  /// Disposes audio player resources.
  ///
  /// Should be called in the dispose method of the State class using this mixin.
  void disposeAudioPlayer() {
    _audioPlayerStateSubscription?.cancel();
    audioPlayer?.dispose();
    voiceMessageEvents.dispose();
    voiceMessageEvent.dispose();
    currentAudioStatus.dispose();
  }
}
