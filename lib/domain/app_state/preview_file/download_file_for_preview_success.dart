import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/model/download_file/download_file_for_preview_response.dart';

class DownloadFileForPreviewSuccess extends Success {
  final DownloadFileForPreviewResponse downloadFileForPreviewResponse;

  const DownloadFileForPreviewSuccess({
    required this.downloadFileForPreviewResponse,
  });

  @override
  List<Object?> get props => [downloadFileForPreviewResponse];
}
