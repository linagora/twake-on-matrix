import 'dart:math';

import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

enum AudioRecordState {
  initial,
  recording,
  recorded,
  playing,
  paused,
}

mixin AudioMixin {
  final ValueNotifier<AudioRecordState> audioRecordStateNotifier =
      ValueNotifier<AudioRecordState>(AudioRecordState.initial);

  void disposeAudioMixin() {
    audioRecordStateNotifier.dispose();
  }

  void startRecording() {
    audioRecordStateNotifier.value = AudioRecordState.recording;
  }

  void stopRecording() {
    audioRecordStateNotifier.value = AudioRecordState.initial;
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
        final double progress =
            min(1.0, (durationInSeconds - 30) / 90); // 0-1 over 30-120s
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
      final int upperIndex =
          (lowerIndex + 1).clamp(0, eventWaveForm.length - 1);

      int sampledValue;
      if (lowerIndex == upperIndex) {
        sampledValue = eventWaveForm[lowerIndex];
      } else {
        final double fraction = exactIndex - lowerIndex;
        final double interpolated = eventWaveForm[lowerIndex] * (1 - fraction) +
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
