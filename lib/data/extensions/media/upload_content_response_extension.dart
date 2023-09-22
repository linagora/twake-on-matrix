import 'package:fluffychat/data/model/media/upload_file_json.dart';
import 'package:fluffychat/domain/model/media/uploaded_content.dart';

extension UploadContentResponseExtension on UploadFileResponse {
  UploadedContent toUploadedContent() {
    return UploadedContent(contentUri);
  }
}
