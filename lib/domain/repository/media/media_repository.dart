import 'package:fluffychat/domain/model/media/uploaded_content.dart';
import 'package:fluffychat/domain/model/media/url_preview.dart';

abstract class MediaRepository {
  Future<UploadedContent> uploadContentForWeb(
    List<int> file, {
    String? contentType,
  });

  Future<UrlPreview> getUrlPreview({
    required Uri uri,
    int? preferredPreviewTime,
  });
}
