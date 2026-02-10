import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart';
import 'package:record/record.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:universal_html/html.dart' as html;

enum AudioRecordState { initial, recording, recorded, playing, paused }

mixin AudioMixin {
  static const waveCount = 40;
  static const maxRecordDurationInSeconds = 1800; // 30 minutes

  final ValueNotifier<int> recordDurationWebNotifier = ValueNotifier<int>(0);

  Timer? _timerWeb;

  late final AudioRecorder _audioRecorder;

  StreamSubscription<RecordState>? _recordSubWeb;

  StreamSubscription<Amplitude>? _amplitudeSubWeb;

  final List<double> _amplitudeTimelineWeb = [];

  final ValueNotifier<AudioRecordState> audioRecordStateNotifier =
      ValueNotifier<AudioRecordState>(AudioRecordState.initial);

  void disposeAudioMixin() {
    audioRecordStateNotifier.dispose();
    _disposeAudioRecorderWeb();
  }

  void startRecording() {
    audioRecordStateNotifier.value = AudioRecordState.recording;
  }

  void stopRecording() {
    audioRecordStateNotifier.value = AudioRecordState.initial;
  }

  void pauseRecording() {
    audioRecordStateNotifier.value = AudioRecordState.paused;
  }

  void deleteRecording() {
    audioRecordStateNotifier.value = AudioRecordState.initial;
  }

  void initAudioRecorderWeb() {
    if (!PlatformInfos.isWeb) return;
    _audioRecorder = AudioRecorder();

    _recordSubWeb = _audioRecorder.onStateChanged().listen((recordState) {
      _updateRecordStateWeb(recordState);
    });

    _amplitudeSubWeb = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
          var value = 100 + amp.current * 2;
          value = value < 1 ? 1 : value;
          _amplitudeTimelineWeb.add(value);
        });
  }

  void _disposeAudioRecorderWeb() {
    if (!PlatformInfos.isWeb) return;
    stopRecordWeb();
    _timerWeb?.cancel();
    _recordSubWeb?.cancel();
    _amplitudeSubWeb?.cancel();
    _audioRecorder.dispose();
    _amplitudeTimelineWeb.clear();
    recordDurationWebNotifier.dispose();
  }

  void _updateRecordStateWeb(RecordState recordState) {
    switch (recordState) {
      case RecordState.pause:
        _timerWeb?.cancel();
        break;
      case RecordState.record:
        _startTimerWeb();
        startRecording();
        break;
      case RecordState.stop:
        stopRecording();
        _timerWeb?.cancel();
        recordDurationWebNotifier.value = 0;
        break;
    }
  }

  void _startTimerWeb() {
    _timerWeb?.cancel();

    _timerWeb = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      recordDurationWebNotifier.value++;

      // Auto-stop recording when reaching max duration (30 minutes)
      if (recordDurationWebNotifier.value >= maxRecordDurationInSeconds) {
        stopRecordWeb();
        t.cancel();
      }
    });
  }

  Future<void> onTapRecorderWeb({required BuildContext context}) async {
    try {
      if (await _audioRecorder.hasPermission()) {
        const encoder = AudioEncoder.wav;

        if (!await _isEncoderSupported(encoder)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(L10n.of(context)!.audioEncoderNotSupportedMessage),
            ),
          );
          return;
        }

        const config = RecordConfig(encoder: encoder, numChannels: 1);

        // Record to file
        await recordFile(_audioRecorder, config);

        recordDurationWebNotifier.value = 0;

        _startTimerWeb();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.of(context)!.microphonePermissionDeniedOnWeb),
          ),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.of(context)!.audioEncoderNotSupportedMessage),
        ),
      );
      return;
    }
  }

  Future<void> recordFile(AudioRecorder recorder, RecordConfig config) {
    return recorder.start(config, path: '');
  }

  Future<bool> _isEncoderSupported(AudioEncoder encoder) async {
    final isSupported = await _audioRecorder.isEncoderSupported(encoder);

    if (!isSupported) {
      Logs().d(
        'AudioMixin: ${encoder.name} is not supported on this platform.',
      );

      for (final e in AudioEncoder.values) {
        if (await _audioRecorder.isEncoderSupported(e)) {
          Logs().d('AudioMixin: - ${e.name}');
        }
      }
    }

    return isSupported;
  }

  Future<String?> stopRecordWeb() async {
    try {
      final value = await _audioRecorder.isRecording();

      if (value == true) {
        return await _audioRecorder.stop();
      }
    } catch (e) {
      debugPrint('Error checking recording status: $e');
    }
    return null;
  }

  Stream<Uint8List> readWebFileAsStream(
    html.File file, {
    int chunkSize = 64 * 1024,
  }) async* {
    if (file.size <= 0) {
      throw Exception('File size must be greater than 0');
    }

    final reader = html.FileReader();
    var offset = 0;

    while (offset < file.size) {
      final end = (offset + chunkSize) > file.size
          ? file.size
          : offset + chunkSize;
      final blob = file.slice(offset, end);

      final completer = Completer<Uint8List>();

      reader.onLoad.listen((_) {
        final result = reader.result;
        if (result is Uint8List) {
          completer.complete(result);
        } else if (result is ByteBuffer) {
          completer.complete(result.asUint8List());
        } else {
          completer.completeError('Unexpected result type');
        }
      });

      reader.onError.listen((event) {
        completer.completeError('FileReader failed: ${reader.error}');
      });

      reader.readAsArrayBuffer(blob);

      yield await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Chunk reading timed out'),
      );

      offset = end;
    }
  }

  Future<html.File?> recordToFileOnWeb({String? blobUrl}) async {
    try {
      if (blobUrl != null) {
        Logs().d(
          'AudioMixin::recordToFileOnWeb: Processing blob URL: $blobUrl',
        );

        // Fetch the actual blob data with timeout
        final response = await html.window
            .fetch(blobUrl)
            .timeout(const Duration(seconds: 10));

        final blob = await response.blob();

        // Create File with correct type
        final file = html.File([blob], 'Voice Message');

        // Clean up the blob URL
        html.Url.revokeObjectUrl(blobUrl);

        Logs().d(
          'AudioMixin::recordToFileOnWeb: ✅ Created file: ${file.name} with type: ${file.type}, size: ${file.size} bytes',
        );
        return file;
      } else {
        Logs().w('AudioMixin::recordToFileOnWeb: No blob URL provided');
      }
    } catch (e, stackTrace) {
      Logs().e('AudioMixin::recordToFileOnWeb: Recording failed: $e');
      Logs().e('AudioMixin::recordToFileOnWeb: Stack trace: $stackTrace');

      // Clean up blob URL on error if it exists
      if (blobUrl != null) {
        try {
          html.Url.revokeObjectUrl(blobUrl);
        } catch (_) {
          // Ignore cleanup errors
        }
      }
    }

    return null;
  }

  // Optional: Helper function to create MatrixAudioFile from the web file
  Future<TwakeAudioFile?> createMatrixAudioFileFromWebFile({
    required html.File file,
    required Duration duration,
  }) async {
    try {
      Logs().d(
        'AudioMixin::createMatrixAudioFileFromWebFile: Processing ${file.name}',
      );

      final formatDate = DateFormat("yyyy-MM-dd-HHmmss").format(DateTime.now());

      final reader = html.FileReader();
      final completer = Completer<void>();

      final loadListener = reader.onLoad.listen((_) => completer.complete());
      final errorListener = reader.onError.listen(
        (event) =>
            completer.completeError('FileReader failed: ${reader.error}'),
      );

      reader.readAsArrayBuffer(file);
      await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('File reading timed out'),
      );

      loadListener.cancel();
      errorListener.cancel();

      return TwakeAudioFile(
        name: 'voice_message_$formatDate.wav',
        bytes: reader.result is Uint8List
            ? reader.result as Uint8List
            : (reader.result as ByteBuffer).asUint8List(),
        mimeType: 'audio/wav',
        duration: duration.inMilliseconds,
      );
    } catch (e, stackTrace) {
      Logs().e(
        'AudioMixin::createMatrixAudioFileFromWebFile: Failed to create MatrixAudioFile: $e',
      );
      Logs().e(
        'AudioMixin::createMatrixAudioFileFromWebFile: Stack trace: $stackTrace',
      );
      rethrow;
    }
  }

  List<int> convertWaveformWeb() {
    final step = _amplitudeTimelineWeb.length < waveCount
        ? 1
        : (_amplitudeTimelineWeb.length / waveCount).round();
    final waveform = <int>[];
    for (var i = 0; i < _amplitudeTimelineWeb.length; i += step) {
      waveform.add((_amplitudeTimelineWeb[i] / 100 * 1024).round());
    }

    return waveform;
  }

  int calculateWaveCountAuto({
    required int minWaves,
    required int maxWaves,
    required int durationInSeconds,
  }) {
    // Automatic breakpoints based on common audio message patterns
    switch (durationInSeconds) {
      case <= 0:
        return minWaves; // Invalid duration
      case <= 2:
        return minWaves;
      case > 2 && <= 10:
        // Short messages: use 20-40% of range
        final double progress = (durationInSeconds - 2) / 8; // 0-1 over 2-10s
        final int rangeSize = ((maxWaves - minWaves) * 0.4).round();
        return (minWaves + rangeSize * progress).round();
      case > 10 && <= 30:
        // Medium messages: use 40-70% of range
        final double progress =
            (durationInSeconds - 10) / 20; // 0-1 over 10-30s
        final int rangeStart = (minWaves + (maxWaves - minWaves) * 0.4).round();
        final int rangeSize = ((maxWaves - minWaves) * 0.3).round();
        return (rangeStart + rangeSize * progress).round();
      default:
        // Long messages: use 70-100% of range
        final double progress = min(
          1.0,
          (durationInSeconds - 30) / 90,
        ); // 0-1 over 30-120s
        final int rangeStart = (minWaves + (maxWaves - minWaves) * 0.7).round();
        final int rangeSize = ((maxWaves - minWaves) * 0.3).round();
        return (rangeStart + rangeSize * progress).round();
    }
  }

  List<int>? calculateWaveForm({
    required List<int>? eventWaveForm,
    required int waveCount,
  }) {
    // Handle edge cases
    if (eventWaveForm == null || eventWaveForm.isEmpty || waveCount <= 0) {
      return null;
    }
    if (waveCount == 1) return [eventWaveForm[eventWaveForm.length ~/ 2]];
    // If we need more data points than we have, generate fake data by repeating the waveform
    if (waveCount > eventWaveForm.length) {
      final List<int> result = [];
      for (int i = 0; i < waveCount; i++) {
        // Cycle through the original waveform to generate fake data
        final int value = eventWaveForm[i % eventWaveForm.length];
        result.add(value);
      }

      // Apply value clamping
      return result.map((i) => i == 0 ? 1 : (i > 1024 ? 1024 : i)).toList();
    }

    // Use interpolation-based sampling instead of insert/remove loops
    final List<int> result = [];
    final double step = (eventWaveForm.length - 1) / (waveCount - 1);

    for (int i = 0; i < waveCount; i++) {
      final double exactIndex = i * step;
      final int lowerIndex = exactIndex.floor();
      final int upperIndex = (lowerIndex + 1).clamp(
        0,
        eventWaveForm.length - 1,
      );

      int sampledValue;
      if (lowerIndex == upperIndex) {
        sampledValue = eventWaveForm[lowerIndex];
      } else {
        final double fraction = exactIndex - lowerIndex;
        final double interpolated =
            eventWaveForm[lowerIndex] * (1 - fraction) +
            eventWaveForm[upperIndex] * fraction;
        sampledValue = interpolated.round();
      }

      result.add(sampledValue);
    }

    // Apply the same value clamping as the original function
    return result.map((i) => i == 0 ? 1 : (i > 1024 ? 1024 : i)).toList();
  }

  List<double> calculateWaveHeight({
    required List<int> waveform,
    required double minHeight, // B
    required double maxHeight, // A
  }) {
    if (waveform.isEmpty) return [];

    final int rawMax = waveform.reduce((a, b) => a > b ? a : b);
    final int rawMin = waveform.reduce((a, b) => a < b ? a : b);

    // Avoid division by zero
    if (rawMax == rawMin) {
      return List<double>.filled(waveform.length, (maxHeight + minHeight) / 2);
    }

    return waveform.map((x) {
      final t = (x - rawMin) / (rawMax - rawMin);
      return minHeight + t * (maxHeight - minHeight);
    }).toList();
  }

  Future<void> preventActionWhileRecordingMobile({
    required BuildContext context,
  }) async {
    await showConfirmAlertDialog(
      context: context,
      title: L10n.of(context)!.recordingInProgress,
      message: L10n.of(context)!.pleaseFinishOrStopTheRecording,
      isArrangeActionButtonsVertical: true,
    );
  }
}
