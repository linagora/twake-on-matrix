import 'package:twake_chat/domain/model/media/url_preview.dart';

abstract class MediaRepository {
  Future<UrlPreview> getUrlPreview({
    required Uri uri,
    int? preferredPreviewTime,
  });
}
