import 'package:just_audio/just_audio.dart';
import 'package:matrix/matrix.dart';

/// Builds a stable [AudioSource] from an in-memory [MatrixFile].
///
/// Uses [AudioSource.uri] with a data URI (stable just_audio API).
AudioSource audioSourceFromMatrixFile(MatrixFile file) {
  return AudioSource.uri(
    Uri.dataFromBytes(file.bytes, mimeType: file.mimeType),
  );
}

extension AudioPlayExtension on AudioPlayer {
  bool get isAtEndPosition {
    final duration = this.duration;
    if (duration == null) return true;
    return position >= duration;
  }
}

extension DuratationExtension on Duration {
  String get minuteSecondString =>
      '${inMinutes.toString().padLeft(2, '0')}:${(inSeconds % 60).toString().padLeft(2, '0')}';
}
