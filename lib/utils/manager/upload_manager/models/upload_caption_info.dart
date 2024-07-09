import 'package:fluffychat/utils/manager/upload_manager/models/upload_info.dart';

class UploadCaptionInfo extends UploadInfo {
  final String caption;

  UploadCaptionInfo({
    required super.txid,
    required this.caption,
  });

  @override
  List<Object?> get props => [txid, caption];
}
