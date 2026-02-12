import 'package:fluffychat/domain/model/file_info/file_info.dart';

class ImageFileInfo extends FileInfo {
  ImageFileInfo(
    super.fileName, {
    super.bytes,
    super.filePath,
    super.customMimeType,
    this.width,
    this.height,
  });

  final int? width;

  final int? height;

  @override
  Map<String, dynamic> get metadata =>
      ({'mimetype': mimeType, 'size': fileSize, 'w': width, 'h': height});

  @override
  List<Object?> get props => [width, height, ...super.props];
}
