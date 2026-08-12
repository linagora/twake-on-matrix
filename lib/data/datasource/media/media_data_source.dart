import 'package:twake_chat/domain/model/media/url_preview.dart';

abstract class MediaDataSource {
  Future<UrlPreview> getUrlPreview({
    required Uri uri,
    int? preferredPreviewTime,
  });
}
