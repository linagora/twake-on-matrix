import 'package:fluffychat/domain/model/file_info/file_info.dart';

class VideoFileInfo extends FileInfo {
  final Duration? duration;

  final int? width;

  final int? height;

  VideoFileInfo(
    super.fileName, {
    super.bytes,
    super.filePath,
    super.customMimeType,
    this.width,
    this.height,
    this.duration,
  });

  @override
  Map<String, dynamic> get metadata => ({
    'mimetype': mimeType,
    'size': fileSize,
    'w': width,
    'h': height,
    if (duration != null) 'duration': duration!.inMilliseconds,
  });

  @override
  List<Object?> get props => [width, height, duration, ...super.props];
}
