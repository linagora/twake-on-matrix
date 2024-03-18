import 'package:fluffychat/domain/model/preview_file/supported_preview_file_types.dart';
import 'package:matrix/matrix.dart';

extension EventInfoExtension on Event {
  bool get isVideoAvailable => !isWmvVideo && !isAviVideo;

  bool get isWmvVideo =>
      SupportedPreviewFileTypes.wmvMineType.contains(attachmentMimetype);

  bool get isAviVideo =>
      SupportedPreviewFileTypes.aviMineType.contains(attachmentMimetype);
}
