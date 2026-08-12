import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/model/download_file/download_file_for_preview_response.dart';

class DownloadFileForPreviewSuccess extends Success {
  final DownloadFileForPreviewResponse downloadFileForPreviewResponse;

  const DownloadFileForPreviewSuccess({
    required this.downloadFileForPreviewResponse,
  });

  @override
  List<Object?> get props => [downloadFileForPreviewResponse];
}
