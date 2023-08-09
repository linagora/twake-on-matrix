import 'package:equatable/equatable.dart';

class DownloadFileForPreviewResponse with EquatableMixin {
  final String filePath;

  final String? mimeType;

  DownloadFileForPreviewResponse({
    required this.filePath,
    this.mimeType,
  });

  @override
  List<Object?> get props => [filePath, mimeType];
}
